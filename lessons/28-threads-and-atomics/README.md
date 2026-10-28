# Lesson 28: Threads and atomics

## Goals

After this lesson you can:

- Start threads with `pthread_create` and wait for them with `pthread_join`,
  passing each thread a struct of its own.
- Explain, instruction by instruction, why `counter++` from two threads loses
  increments.
- Protect shared data with a `pthread_mutex_t`.
- Write atomic read-modify-write loops with the exclusive pair `ldxr`/`stxr`.
- Use the single-instruction ARMv8.1 atomics `ldadd`, `swp`, and `cas`.
- Explain memory ordering, and use `ldar`/`stlr`, `ldaxr`/`stlxr`, and
  `dmb ish` to get the ordering you need.
- Build a spinlock from scratch.
- Read the instructions a compiler emits for C11 `<stdatomic.h>`.

## Before you start

You need lesson 15 (the calling convention: which registers survive a call),
lesson 19 (structs and `.equ` field offsets), lesson 21 (`malloc`/`free`), and
lesson 24 (passing a function's address with `adr` and calling through a
pointer). Every program here is a libc program with a `main`, like everything
since lesson 16.

The container has 4 CPU cores. Threads really do run at the same time, which
is exactly what makes this lesson interesting.

## 1. What a thread is

So far each program has had one *thread of execution*: one `pc`, one set of
registers, one stack, running one instruction after another. A thread is a
second (third, fourth...) one of those, inside the same program. Every thread
has its **own registers and its own stack**, but they all **share the same
memory**: the same `.data`, `.bss`, heap, and code.

In C:

```c
#include <pthread.h>
#include <stdio.h>

struct work { long start; long end; long result; };   // end is exclusive

void *sum_range(void *arg) {
    struct work *w = arg;
    long sum = 0;
    for (long i = w->start; i < w->end; i++)
        sum += i;
    w->result = sum;
    return NULL;
}

pthread_t tids[4];
struct work work[4];

int main(void) {
    for (long i = 0; i < 4; i++) {
        work[i] = (struct work){ i * 250 + 1, i * 250 + 251, 0 };
        pthread_create(&tids[i], NULL, sum_range, &work[i]);
    }
    for (long i = 0; i < 4; i++)
        pthread_join(tids[i], NULL);
    long total = 0;
    for (long i = 0; i < 4; i++) {
        printf("thread %ld: sum of %ld..%ld = %ld\n",
               i, work[i].start, work[i].end - 1, work[i].result);
        total += work[i].result;
    }
    printf("total = %ld\n", total);
}
```

The two functions you need:

| Call | Arguments | Returns |
|------|-----------|---------|
| `pthread_create(&tid, attr, fn, arg)` | `x0` = where to store the new thread's id, `x1` = attributes (`NULL` = defaults), `x2` = the function to run, `x3` = the one argument passed to it | `w0` = 0 on success, an error number otherwise |
| `pthread_join(tid, &ret)` | `x0` = the thread id (the value, not its address), `x1` = where to store the thread's return value (`NULL` = don't care) | `w0` = 0 on success |

A thread function has the C type `void *fn(void *arg)`: it receives one
pointer in `x0` and returns one pointer in `x0`. When it returns, the thread
ends. To give a thread several values, put them in a struct and pass the
struct's address. A `pthread_t` is 8 bytes on both platforms.

Read [examples/threads.s](examples/threads.s). Three things to notice:

- `sum_range` is an ordinary function. It follows the calling convention
  exactly like any other: it is a leaf, so it needs no frame. The thread
  library calls it for you on a brand-new stack.
- The function's address goes into `x2` with `adr x2, sum_range`, exactly as
  you passed `qsort` a comparator in lesson 24.
- `x3` holds `&work[i]`, computed with `madd` from the index and the struct size.

Predict: is the output always the same, even though the threads run in
whatever order the operating system likes?

```console
$ make
$ ./threads
thread 0: sum of 1..250 = 31375
thread 1: sum of 251..500 = 93875
thread 2: sum of 501..750 = 156375
thread 3: sum of 751..1000 = 218875
total = 500500
```

Yes. Each thread only writes its *own* struct, and `main` reads the results
only after `pthread_join` has returned for every thread. `pthread_join` does
two jobs: it waits, and it guarantees that everything the finished thread
wrote to memory is now visible to the joining thread.

### Linking with -pthread

On Linux, programs that use threads are linked with `gcc -pthread`. (On the
glibc in our container the pthread functions live in libc itself, so it would
link anyway, but older systems fail with `undefined reference to
pthread_create`, and `-pthread` also sets up the compiler correctly for C
code.) The shared `mk/linux.mk` rule does not add it, so this lesson's
Makefile replaces that rule with one that does:

```make
include ../../../mk/linux.mk

%: %.s
	$(CC) $(ASFLAGS) -pthread -o $@ $<
```

A pattern rule with the same target and prerequisite as an earlier one
replaces it, so every `.s` in the directory now links with `-pthread`.

## 2. A data race

Now let four threads share one variable. Each adds 1 to a global counter a
million times:

```c
long counter = 0;

void *worker(void *arg) {
    for (long i = 0; i < 1000000; i++)
        counter++;
    return NULL;
}
```

Four threads, a million each: you expect 4000000. In assembly `counter++` is
three instructions (look at [examples/race.s](examples/race.s)):

```asm
    ldr     x3, [x1]                // read counter
    add     x3, x3, #1              // add one
    str     x3, [x1]                // write it back
```

Predict what `./race` prints. Then run it a few times:

```console
$ ./race
expected 4000000, got 1842102
$ ./race
expected 4000000, got 1098785
$ ./race
expected 4000000, got 1452763
```

Different every time, and wrong by millions. Here is why. Two threads, A and
B, on two cores, counter starts at 5:

| Step | Thread A | Thread B | counter in memory |
|------|----------|----------|-------------------|
| 1 | `ldr x3` gets 5 | | 5 |
| 2 | | `ldr x3` gets 5 | 5 |
| 3 | `add` makes 6 | `add` makes 6 | 5 |
| 4 | `str` writes 6 | | 6 |
| 5 | | `str` writes 6 | 6 |

Two increments happened; the counter went up by one. B's load happened
between A's load and A's store, so B worked from a stale value. This is a
**data race**: two threads access the same memory at the same time, at least
one of them writes, and nothing orders the accesses. In C a data race is
undefined behaviour; in assembly it is perfectly defined, just useless.

Note that each individual `ldr` and `str` of an aligned 8-byte value *is*
atomic: you never see half of one write and half of another. The problem is
that the *sequence* load-add-store is not.

There are three ways to fix it, and this lesson shows all three: a lock, an
exclusive load/store loop, and a single atomic instruction.

## 3. Fix 1: a mutex

A mutex ("mutual exclusion") is a lock from the pthread library. Only one
thread at a time can hold it; any other thread that calls
`pthread_mutex_lock` waits (the OS puts it to sleep) until the holder calls
`pthread_mutex_unlock`.

```c
pthread_mutex_t lock;

void *worker(void *arg) {
    for (long i = 0; i < 1000000; i++) {
        pthread_mutex_lock(&lock);
        counter++;                    // only one thread at a time gets here
        pthread_mutex_unlock(&lock);
    }
    return NULL;
}

int main(void) {
    pthread_mutex_init(&lock, NULL);
    ...start and join the threads...
    pthread_mutex_destroy(&lock);
}
```

The code between lock and unlock is called the **critical section**. Read
[examples/mutex.s](examples/mutex.s). The worker now calls functions in its
loop, so it needs a frame, and it keeps the mutex address and the loop count
in `x19` and `x20`, which survive calls (lesson 15). Everything in `x0`-`x17`
may be destroyed by `pthread_mutex_lock`.

Where does the mutex live? A `pthread_mutex_t` is just a struct in memory:
48 bytes on Linux AArch64, 64 on macOS. You never look inside it; you only
pass its address. The program reserves 64 bytes in `.bss` (enough on both) and
calls `pthread_mutex_init` before starting any thread.

```console
$ ./mutex
expected 4000000, got 4000000
```

Every time. In C you can also write `pthread_mutex_t lock =
PTHREAD_MUTEX_INITIALIZER;` instead of calling `pthread_mutex_init`. On glibc
that initializer happens to be all zero bytes, so a zeroed `.bss` mutex works
there, but on macOS it contains a signature word, so zeroes are *not* a valid
mutex. Calling `pthread_mutex_init` is correct everywhere.

## 4. Fix 2: exclusive loads and stores

A mutex works, but it is a library call (or two) for a single `add`. The CPU
can make a read-modify-write atomic directly. The original AArch64 way is a
pair of instructions:

| Instruction | Effect |
|-------------|--------|
| `ldxr Xt, [Xn]` | Load, and tell the CPU's *exclusive monitor* to watch this address. |
| `stxr Ws, Xt, [Xn]` | Store `Xt` **only if** nobody else has written that address since our `ldxr`. Put 0 in `Ws` if the store happened, 1 if it did not. |

The C equivalent is an idea rather than a statement: "load it, compute, and
store only if it is still what I loaded; if not, try again":

```c
do {
    old = counter;          // ldxr
    new = old + 1;          // add
} while (!store_if_untouched(&counter, new));   // stxr + cbnz
```

From [examples/ldxr.s](examples/ldxr.s):

```asm
retry:
    ldxr    x3, [x1]                // load counter AND start watching its address
    add     x3, x3, #1
    stxr    w4, x3, [x1]            // w4 = 0 on success, 1 on failure
    cbnz    w4, retry               // failed: someone got in first, start over
```

Replay the race table. A and B both `ldxr` 5. A's `stxr` succeeds and writes
6. B's monitor saw that write, so B's `stxr` *fails*, stores nothing, and sets
`w4` = 1. B goes back, loads 6, and stores 7. No increment is lost.

```console
$ ./ldxr
expected 4000000, got 4000000
```

Rules for exclusive pairs:

- **No offset.** The address is `[Xn]` only. `ldxr x1, [x0, #8]` is an
  assembler error; compute the address first with `add`.
- **The status register must differ** from the value and address registers.
  `stxr w1, x1, [x0]` is rejected (by clang) or warned about (by GNU as) as
  "unpredictable".
- **Keep the loop tiny.** Between `ldxr` and `stxr` do only a few simple
  register instructions. A function call, another load or store, or an
  interrupt may clear the monitor; if that happens on every attempt, the loop
  never succeeds.
- **Natural alignment.** An 8-byte exclusive access needs an 8-byte aligned
  address, or the program dies with a bus error.
- Sizes: `ldxrb`/`stxrb` (byte), `ldxrh`/`stxrh` (halfword), `w` registers
  for 4 bytes, `x` registers for 8.
- If you `ldxr` and then decide not to store (for example a "store only if
  bigger" operation), execute `clrex` to tell the monitor you are done.

## 5. Fix 3: one atomic instruction (ARMv8.1 LSE)

Exclusive loops work everywhere, but under heavy contention many cores keep
failing and retrying. ARMv8.1 added the **Large System Extensions (LSE)**:
single instructions that do the whole read-modify-write inside the memory
system. Every Apple M-series chip and every recent Arm server core has them,
and so does the CPU under our container.

| Instruction | Effect, all of it atomic | C11 |
|-------------|--------------------------|-----|
| `ldadd Xs, Xt, [Xn]` | `Xt = *Xn; *Xn = Xt + Xs` | `atomic_fetch_add` |
| `ldclr Xs, Xt, [Xn]` | `Xt = *Xn; *Xn = Xt & ~Xs` | `atomic_fetch_and` (with `~`) |
| `ldset Xs, Xt, [Xn]` | `Xt = *Xn; *Xn = Xt \| Xs` | `atomic_fetch_or` |
| `ldeor Xs, Xt, [Xn]` | `Xt = *Xn; *Xn = Xt ^ Xs` | `atomic_fetch_xor` |
| `ldsmax`, `ldsmin`, `ldumax`, `ldumin` | store the max/min, return the old value | (none) |
| `stadd Xs, [Xn]` | `*Xn += Xs`, old value not needed | `atomic_fetch_add`, result unused |
| `swp Xs, Xt, [Xn]` | `Xt = *Xn; *Xn = Xs` | `atomic_exchange` |
| `cas Xs, Xt, [Xn]` | `if (*Xn == Xs) *Xn = Xt;` and always `Xs = old *Xn` | `atomic_compare_exchange_strong` |

Note the operand order: the value going *in* comes first, the old value coming
*out* second. `cas` is different again: its first register is both "the value
I expect" going in and "the value that was really there" coming out. It
succeeded if those are equal, so you compare afterwards.

The assembler has to be told the CPU has these instructions. Without it:

```console
$ gcc lse.s -o lse            # lse.s with its .arch line deleted
lse.s: Assembler messages:
lse.s:30: Error: selected processor does not support `ldadd x3,x4,[x1]'
lse.s:73: Error: selected processor does not support `swp x1,x20,[x19]'
```

Put this directive at the top of the file:

```asm
    .arch armv8.1-a
```

(The command-line alternative is `gcc -march=armv8.1-a`.) Read
[examples/lse.s](examples/lse.s). The worker's loop body is now one
instruction:

```asm
    ldadd   x3, x4, [x1]            // atomically: x4 = counter; counter += x3
```

After the threads finish, `main` demonstrates `swp` and `cas` on one thread.
Predict all four lines, then run it:

```console
$ ./lse
ldadd: counter = 4000000
swp 7: got old 4000000, counter = 7
cas 7->100: saw 7, counter = 100
cas 7->200: saw 100, counter = 100
```

The second `cas` expected 7 but memory held 100, so it stored nothing and
handed back 100. A caller in a loop would now retry using 100 as its new guess.

## 6. Memory ordering

Atomicity is one problem. Ordering is the other, and it is subtler.

To go fast, an AArch64 core may make its loads and stores visible to *other*
cores in a different order from the program order. (Your own thread always
sees its own accesses in program order.) Consider passing a message:

```c
long data;  int flag;

// producer thread           // consumer thread
data = 42;                   while (flag == 0) ;
flag = 1;                    printf("%ld\n", data);
```

With plain `str` and `ldr`, the consumer could see `flag == 1` and still read
the old `data`: the core may let the store to `flag` become visible before the
store to `data`, or the consumer's core may perform the `data` load early.
x86 forbids most of this; Arm allows it. The program is wrong even though
every line looks right.

The fix is to say which accesses must stay in order:

| Instruction | Name | Guarantee |
|-------------|------|-----------|
| `stlr Wt, [Xn]` | store-release | Every load and store *before* it in program order is visible before this store. |
| `ldar Wt, [Xn]` | load-acquire | Every load and store *after* it in program order happens after this load. |
| `ldaxr` / `stlxr` | exclusive versions | `ldxr` with acquire / `stxr` with release. |
| `ldadda`, `ldaddl`, `ldaddal`, `swpa`, `casal`, ... | LSE versions | suffix `a` = acquire, `l` = release, `al` = both. |
| `dmb ish` | data memory barrier | No load or store crosses it, in either direction. |
| `dmb ishld` | load barrier | Loads before it complete before any later load or store. |

`ish` means "inner shareable": all the cores running this program. Like
`ldxr`, `ldar` and `stlr` take only `[Xn]`, no offset.

Release and acquire come in pairs. The producer *releases* (publishes) with
`stlr`; the consumer *acquires* with `ldar`; if the acquire sees the value the
release wrote, then everything the producer did before the release is visible
to the consumer after the acquire. Read
[examples/msgpass.s](examples/msgpass.s):

```asm
// producer
    str     x2, [x1]                // data = 42            (plain store)
    stlr    w2, [x1]                // flag = 1, release: data is visible first
// consumer (main)
wait:
    ldar    w1, [x19]               // read flag, acquire
    cbz     w1, wait                // while (flag == 0) ;
    ldr     x1, [x1, :lo12:data]    // plain load: guaranteed to see 42
```

```console
$ ./msgpass
flag is set, data = 42
```

The older way to write the same thing uses plain accesses plus full barriers:

```asm
// producer                       // consumer
    str     x2, [data]            wait: ldr  w1, [flag]
    dmb     ish                         cbz  w1, wait
    str     w3, [flag]                  dmb  ish
                                        ldr  x1, [data]
```

Both are correct. `ldar`/`stlr` is cheaper because it only orders what it has
to, and it is what compilers emit. Use `dmb ish` when you need a standalone
fence (C's `atomic_thread_fence`).

Why did `race.s` and `ldxr.s` not need any of this? Because they only care
about the final count, which `main` reads *after* `pthread_join`. The join
already provides the ordering. A plain `ldxr`/`stxr` (or `ldadd`) is atomic
but unordered: C calls that `memory_order_relaxed`, and it is all a counter
needs. A lock, on the other hand, protects *other* data, so it needs ordering.

## 7. Building a spinlock

A mutex puts a waiting thread to sleep. A **spinlock** just loops until the
lock is free. That wastes CPU, but if critical sections are a handful of
instructions it can be faster than asking the OS. Building one shows how a
lock works inside.

The lock is one 4-byte word: 0 = free, 1 = held.

```c
void spin_lock(int *lock)   { while (!compare_and_set(lock, 0, 1)) ; }  // acquire
void spin_unlock(int *lock) { *lock = 0; }                              // release
```

From [examples/spinlock.s](examples/spinlock.s):

```asm
spin_lock:
    mov     w2, #1
spin_retry:
    ldaxr   w1, [x0]                // read the lock word (acquire), start watching
    cbnz    w1, spin_retry          // 1 = someone holds it: keep trying
    stxr    w3, w2, [x0]            // try to write 1
    cbnz    w3, spin_retry          // someone else wrote first: try again
    ret

spin_unlock:
    stlr    wzr, [x0]               // *lock = 0, release
    ret
```

The ordering is the important part. Taking the lock uses **acquire**, so
nothing inside the critical section can happen before we own the lock.
Releasing uses **release**, so everything inside the critical section is
visible before the lock looks free. Without them, the next thread could take
the lock and still read an old `counter`. This acquire-on-lock,
release-on-unlock pattern is exactly what `pthread_mutex_lock` does inside.

```console
$ ./spinlock
expected 4000000, got 4000000
```

Spinlocks have real drawbacks: a waiting thread burns a whole core, and if the
holder is descheduled, everyone spins until it runs again. Use a pthread mutex
in real programs; build spinlocks to understand them. (Real spinlocks also
add a `wfe` "wait for event" instruction to the spin, to save power. That is
beyond this course.)

## 8. C11 atomics and what they become

C11's `<stdatomic.h>` gives you these instructions from C. Read
[examples/c11.c](examples/c11.c). It wraps four operations in small
functions so you can find them in the disassembly:

```c
atomic_long counter;
long bump(void)                    { return atomic_fetch_add(&counter, 1); }
int  swap_if(long e, long d)       { return atomic_compare_exchange_strong(&counter, &e, d); }
long peek(void)                    { return atomic_load_explicit(&counter, memory_order_acquire); }
void publish(long v)               { atomic_store_explicit(&counter, v, memory_order_release); }
```

Ask gcc for the LSE version:

```console
$ gcc -O2 -march=armv8.1-a -S c11.c -o - | less
bump:
        adrp    x1, .LANCHOR0
        mov     x0, 1
        add     x1, x1, :lo12:.LANCHOR0
        ldaddal x0, x0, [x1]
        ret
swap_if:
        mov     x3, x0
        adrp    x2, .LANCHOR0
        add     x2, x2, :lo12:.LANCHOR0
        casal   x3, x1, [x2]
        cmp     x3, x0
        cset    w0, eq
        ret
peek:   ...     ldar    x0, [x0]
publish: ...    stlr    x0, [x1]
```

`swap_if` is the `cas` pattern from `lse.s`: copy "expected", `cas`, compare
what came back with what was expected, turn the flags into 0 or 1 with `cset`.

Now without `-march`:

```console
$ gcc -O2 -S c11.c -o - | grep 'bl.*__aarch64'
        bl      __aarch64_ldadd8_acq_rel
        bl      __aarch64_cas8_acq_rel
```

gcc does not know whether the machine that runs the program will have LSE,
so by default (`-moutline-atomics`) it calls tiny helper functions that check
the CPU once and then use either the LSE instruction or an `ldaxr`/`stlxr`
loop. `peek` and `publish` need no read-modify-write, so they are `ldar` and
`stlr` either way. Build and run it:

```console
$ ./c11
after two bumps: 2
cas 2->10: 1, counter = 10
cas 2->20: 0, counter = 10
after publish: 99
```

The mapping, for 8-byte values (use `w` registers for `atomic_int`):

| C11 | Default order (seq_cst) | With LSE | Without LSE |
|-----|------------------------|----------|-------------|
| `atomic_load(&x)` | | `ldar` | `ldar` |
| `atomic_store(&x, v)` | | `stlr` | `stlr` |
| `atomic_fetch_add(&x, v)` | acquire + release | `ldaddal` | `ldaxr` / `add` / `stlxr` loop |
| `atomic_fetch_add_explicit(..., memory_order_relaxed)` | none | `ldadd` | `ldxr` / `add` / `stxr` loop |
| `atomic_exchange(&x, v)` | | `swpal` | `ldaxr` / `stlxr` loop |
| `atomic_compare_exchange_strong(&x, &e, d)` | | `casal` + `cmp` | `ldaxr` / `cmp` / `stlxr` loop |
| `atomic_thread_fence(memory_order_seq_cst)` | | `dmb ish` | `dmb ish` |
| `atomic_thread_fence(memory_order_acquire)` | | `dmb ishld` | `dmb ishld` |

A `_explicit` call with `memory_order_acquire` drops the `l`
(`ldadda`), `memory_order_release` drops the `a` (`ldaddl`).

## 9. Thread-local storage, briefly

C11 also has `_Thread_local long x;`: a global of which every thread has its
own copy. On Linux the compiler finds the current thread's copy through a
special register, `tpidr_el0`, that holds a pointer to the thread's block of
thread-locals (`mrs x0, tpidr_el0` reads it), plus an offset the linker works
out. macOS does it differently, through a descriptor and a function call. You
will rarely write this by hand; if you need a per-thread value in assembly,
the simple way is the one `threads.s` already uses: give each thread its own
struct and pass the pointer.

## 10. How fast is each fix?

Crude timings from the container (`time ./prog`, 4 threads, 4 million
increments). Yours will differ; the order usually does not.

| Program | Method | Result | Time |
|---------|--------|--------|------|
| `race` | plain `ldr`/`add`/`str` | wrong | 0.004 s |
| `ldxr` | exclusive loop | right | 0.045 s |
| `lse` | `ldadd` | right | 0.050 s |
| `mutex` | `pthread_mutex_lock` | right | 0.11 s |
| `spinlock` | `ldaxr`/`stxr` + `stlr` | right | 0.13 s |

The race is fastest because it is wrong: the cores barely talk to each other.
Every correct version has to move the counter's cache line between cores for
every increment. The real lesson: shared writes are expensive. `ex4` in the
homework shows the fix, which is to do the work in private registers and
combine once at the end.

## C to assembly

| C | AArch64 |
|---|---------|
| `pthread_create(&t, NULL, fn, arg)` | `x0`=`&t`, `x1`=0, `adr x2, fn`, `x3`=arg, `bl pthread_create` |
| `pthread_join(t, NULL)` | `ldr x0, [t]`, `mov x1, #0`, `bl pthread_join` |
| `void *fn(void *arg) { ...; return NULL; }` | arg in `x0`, `mov x0, #0`, `ret` |
| `pthread_mutex_lock(&m)` / `unlock` | `x0` = `&m`, `bl` |
| `counter++` (not atomic!) | `ldr` / `add` / `str` |
| `atomic_fetch_add_explicit(&x, 1, relaxed)` | `ldxr`/`add`/`stxr`/`cbnz` loop, or `ldadd` |
| `atomic_fetch_add(&x, 1)` | `ldaddal`, or `ldaxr`/`add`/`stlxr` loop |
| `atomic_exchange(&x, v)` | `swpal` |
| `atomic_compare_exchange_strong(&x, &e, d)` | `casal` then `cmp`/`cset` |
| `atomic_load_explicit(&x, acquire)` | `ldar` |
| `atomic_store_explicit(&x, v, release)` | `stlr` |
| `atomic_thread_fence(seq_cst)` | `dmb ish` |

## Common mistakes

- **Reading results before `pthread_join`.** The threads may not have run
  yet: you print zeros, or half-finished values. Join first.
- **Passing `&tids[i]` to `pthread_join`.** Join wants the id itself
  (`ldr x0, [x20, x21, lsl #3]`), create wants its address. Mixing them up
  gives `ESRCH` or a crash.
- **Passing a pointer to something that dies.** If you build a thread's
  struct in `main`'s stack frame and return (or reuse the slot) before the
  thread reads it, the thread reads garbage. Globals or the heap are safe.
- **Losing values across calls in the thread function.** It is an ordinary
  function: `x0`-`x17` die at every `bl`. Keep loop counters in `x19`-`x28`
  and save them in the prologue.
- **`ldadd` rejected with "selected processor does not support".** Add
  `.arch armv8.1-a` at the top of the file.
- **An offset on `ldxr`, `stxr`, `ldar`, or `stlr`.** "the optional immediate
  offset can only be 0". Compute the address into a register first.
- **The same register for the `stxr` status and the value.** Rejected as
  "unpredictable". Use a separate `w` register for the status.
- **A call or extra memory access inside an `ldxr`/`stxr` loop.** It may
  never succeed. Keep the loop to a few register instructions.
- **Forgetting acquire/release in a lock.** It usually works in testing and
  fails rarely in production. Lock with acquire, unlock with release.
- **A zero-filled `pthread_mutex_t` on macOS.** It is not a valid mutex there.
  Call `pthread_mutex_init`.
- **Misaligned atomics.** Exclusive and LSE accesses need natural alignment;
  put `.p2align 3` before 8-byte variables.

## Recap

- A thread has its own registers and stack but shares memory with every
  other thread in the program.
- `pthread_create(&tid, NULL, fn, arg)` starts `fn(arg)`; `pthread_join(tid,
  NULL)` waits for it and makes its writes visible.
- `counter++` is load-add-store; two threads can interleave and lose updates.
- A mutex makes a critical section run one thread at a time.
- `ldxr`/`stxr` make a read-modify-write atomic by retrying until nobody
  interfered; `stxr` reports 0 for success.
- ARMv8.1 LSE (`ldadd`, `swp`, `cas`, ...) does it in one instruction; tell
  the assembler with `.arch armv8.1-a`.
- Cores may reorder memory accesses as seen by other cores. `stlr` (release)
  and `ldar` (acquire) pair up to publish data safely; `dmb ish` is a full fence.
- A lock is an atomic swap or compare-and-set with acquire, plus a release
  store to unlock.
- C11 atomics map directly onto these instructions; the default `seq_cst`
  order becomes the `al` forms.

## Homework

[exercises.md](exercises.md)
