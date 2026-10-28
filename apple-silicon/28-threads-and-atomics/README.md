# Lesson 28 on Apple Silicon: threads and atomics

Do [lesson 28](../../lessons/28-threads-and-atomics/README.md) first. The
threads, the races, and every atomic instruction are identical on macOS: an
M-series core runs `ldxr`, `stxr`, `ldadd`, `cas`, `ldar`, `stlr`, and
`dmb ish` exactly as described there. This page covers what is different
around them, then walks through the macOS version of each example.

## What differs

| Topic | Linux | macOS |
|-------|-------|-------|
| Linking threaded programs | `gcc -pthread` | nothing extra: pthreads is part of libSystem |
| Function names | `pthread_create`, ... | `_pthread_create`, `_pthread_join`, `_pthread_mutex_lock`, ... |
| `sizeof(pthread_t)` | 8 (an integer id) | 8 (a pointer to a thread struct) |
| `sizeof(pthread_mutex_t)` | 48 | 64 |
| `PTHREAD_MUTEX_INITIALIZER` | all zero bytes | a signature word `0x32AAABA7` then zeroes |
| LSE atomics (`ldadd`, `cas`, ...) | need `.arch armv8.1-a` or `-march=armv8.1-a` | accepted by default: clang targets the Apple M1 or later, which has them |
| C11 atomics from `clang -O2` | `__aarch64_*` helper calls unless `-march=armv8.1-a` | direct `ldaddal`, `casal`, ... |
| Thread-local storage | `tpidr_el0` + offset | a descriptor (`@TLVPPAGE`) and a call to its getter |
| Cores | 4 in the container | all of your Mac's cores, a mix of performance and efficiency cores |

The calling convention for the thread function is the standard one:
`pthread_create` and `pthread_join` are **not** variadic, so their arguments
go in `x0`-`x3` on macOS too. Only `printf` needs the stack treatment.

### The mutex

A zero-filled `.bss` mutex happens to work on glibc. It does **not** on
macOS: `PTHREAD_MUTEX_INITIALIZER` there is

```c
{ 0x32AAABA7, { 0 } }     // a "this is a mutex" signature, then 56 zero bytes
```

and the library checks that signature. Calling `pthread_mutex_init(&lock,
NULL)` first, as `mutex.s` does on both platforms, is always correct. The
64 bytes reserved in `.bss` are exactly the macOS size.

### The `.arch` line

The macOS examples keep `.arch armv8.1-a` so the files match the Linux ones.
Apple's clang accepts it, but does not need it: without the line, `ldadd`
still assembles, because clang's default target for `-arch arm64` on macOS is
an M1, which is ARMv8.5 with LSE. Try it: delete the line from a copy of
`lse.s` and build.

## Building

```console
$ cd apple-silicon/28-threads-and-atomics/examples
$ make
$ ./threads
```

The Makefile is just the shared `apple.mk` plus a rule for `c11` (built from
C at `-O2`). There is no `-pthread` rule because none is needed.

## Walking through the examples

Every example has the same structure as on Linux. The changes are the usual
macOS ones from earlier lessons: `_main`, `_`-prefixed library functions,
`@PAGE`/`@PAGEOFF`, `__TEXT,__cstring` for strings, and `printf`'s variadic
arguments stored on the stack.

### threads.s

The thread function and the create/join loops are unchanged except for the
names. The difference is the `printf` in `print_loop`, which has four
variadic arguments after the format string, so they go in four stack slots:

```asm
    sub     sp, sp, #32             // variadic arguments go on the stack
    stp     x1, x2, [sp]            // i, start
    stp     x3, x4, [sp, #16]       // end - 1, result
    bl      _printf
    add     sp, sp, #32
```

```console
$ ./threads
thread 0: sum of 1..250 = 31375
thread 1: sum of 251..500 = 93875
thread 2: sum of 501..750 = 156375
thread 3: sum of 751..1000 = 218875
total = 500500
```

Note `adr x2, sum_range` still works: `sum_range` is in the same file and
section, so a PC-relative `adr` reaches it. No `@PAGE` is needed for `adr`.

### race.s

```console
$ ./race
expected 4000000, got 1187066
$ ./race
expected 4000000, got 1659347
```

A Mac has more cores than the container, so all four threads really do run at
once, and increments are lost just as badly. Because performance and
efficiency cores run at different speeds, the numbers jump around more.

### mutex.s

`pthread_mutex_init`, `_lock`, `_unlock`, and `_destroy` become
`_pthread_mutex_init` and so on, and `lock` is 64 bytes. Output, every time:

```console
$ ./mutex
expected 4000000, got 4000000
```

### ldxr.s, lse.s, spinlock.s, msgpass.s

The atomic parts are byte-for-byte the same as on Linux. Only the addresses
(`counter@PAGE`, `counter@PAGEOFF`) and the `printf` calls change:

```asm
    sub     sp, sp, #16             // variadic arguments go on the stack
    stp     x1, x2, [sp]            // expected, got
    bl      _printf
    add     sp, sp, #16
```

```console
$ ./ldxr
expected 4000000, got 4000000
$ ./lse
ldadd: counter = 4000000
swp 7: got old 4000000, counter = 7
cas 7->100: saw 7, counter = 100
cas 7->200: saw 100, counter = 100
$ ./spinlock
expected 4000000, got 4000000
$ ./msgpass
flag is set, data = 42
```

Rough timings on an M4 Pro (`time ./prog`):

| Program | Time |
|---------|------|
| `race` (wrong) | under 0.01 s |
| `ldxr` | 0.02-0.03 s |
| `lse` | 0.03-0.04 s |
| `mutex` | 0.04-0.06 s |
| `spinlock` | 0.11-0.14 s |

### c11.c

Apple's clang knows every Mac it targets has LSE, so `-O2` emits the
instructions directly, with no helper calls:

```console
$ objdump -d --no-show-raw-insn c11 | grep -A5 '<_bump>:'
00000001000004f8 <_bump>:
1000004f8:      adrp    x8, 0x100008000 <_counter>
1000004fc:      add     x8, x8, #0x0
100000500:      mov     w9, #0x1
100000504:      ldaddal x9, x0, [x8]
100000508:      ret
```

`_swap_if` is `casal` followed by `cmp` and `cset`, `_peek` is `ldar`, and
`_publish` is `stlr`, exactly the mapping table in the main lesson. (Addresses
will differ on your machine.) To see the source-level version run
`clang -O2 -S c11.c -o -`.

```console
$ ./c11
after two bumps: 2
cas 2->10: 1, counter = 10
cas 2->20: 0, counter = 10
after publish: 99
```

### Thread-local storage

For completeness: on macOS, `_Thread_local long x;` compiles to a load of a
descriptor with `adrp x0, _x@TLVPPAGE` / `ldr x0, [x0, _x@TLVPPAGEOFF]`,
then a call through the descriptor's first word, which returns the address of
this thread's copy in `x0`. You do not need to write this by hand; per-thread
structs passed as the thread argument are simpler.

## Solutions

[solutions/](solutions/) has macOS versions of `ex4.s` to `ex8.s`. Each one
differs from the Linux solution only in symbol names, `@PAGE`/`@PAGEOFF`, and
the stack-based `printf` arguments (`ex7.s` also calls `_malloc` and `_free`).
Expected output is the same:

```console
$ cd apple-silicon/28-threads-and-atomics/solutions
$ make
$ ./ex4
total = 8000002000000
$ ./ex5
max = 1000002
$ ./ex6
counter = 4000000
$ ./ex7
nodes = 4000, sum = 7998000
$ ./ex8
counter = 800000
```
