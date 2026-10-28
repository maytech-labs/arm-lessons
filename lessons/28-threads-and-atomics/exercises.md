# Lesson 28 exercises

Work in a `work/` directory inside this lesson (it is git-ignored):

```console
$ mkdir -p lessons/28-threads-and-atomics/work
$ cd lessons/28-threads-and-atomics/work
$ cp ../examples/Makefile .     # links every .s with -pthread
```

(Delete the `c11` lines from the copied Makefile, or copy `c11.c` too.)
Solutions are in [solutions/](solutions/), written answers in
[solutions/README.md](solutions/README.md). Try each exercise properly before
you look. Run every threaded program several times: a bug that shows up one
run in ten is still a bug.

For programs that use LSE instructions, put `.arch armv8.1-a` at the top.

---

## Exercise 28.1 [warm-up]

Written.

(a) `counter` starts at 0. Two threads each run `counter++` exactly **once**,
compiled as `ldr` / `add` / `str`. List every final value `counter` can have,
and for each one, write out an interleaving (a table like the one in section 2)
that produces it.

(b) In `examples/threads.s`, suppose you moved the `print_loop` so it runs
*before* the `join_loop`. What could the output look like? Could it ever be
correct? Could it ever be *guaranteed* correct?

## Exercise 28.2 [warm-up]

Written. About this loop:

```asm
retry:
    ldxr    x3, [x1]
    add     x3, x3, #1
    stxr    w4, x3, [x1]
    cbnz    w4, retry
```

(a) What is in `w4` after a successful `stxr`? After a failed one?
(b) When the `stxr` fails, what is in memory at `[x1]`: the old value, the new
one, or something else?
(c) Why can't you replace `stxr w4, x3, [x1]` with `stxr w3, x3, [x1]`?
(d) Someone "improves" the loop by adding `bl printf` between the `add` and
the `stxr` to trace it. What may happen, and why?
(e) This loop has no acquire or release. Explain why `ldxr.s` still always
prints 4000000.

## Exercise 28.3 [core]

Written. For each C11 operation on an `atomic_long x`, write the instruction
(or instructions) gcc emits with `-O2 -march=armv8.1-a`, and what it becomes
without LSE. Then check yourself: put each in a small function in a `.c`
file and run `gcc -O2 -march=armv8.1-a -S file.c -o -` and
`gcc -O2 -march=armv8-a+nolse -mno-outline-atomics -S file.c -o -`.

1. `atomic_fetch_add(&x, 1)`
2. `atomic_fetch_add_explicit(&x, 1, memory_order_relaxed)`
3. `atomic_load(&x)`
4. `atomic_store(&x, v)`
5. `atomic_exchange(&x, v)`
6. `atomic_compare_exchange_strong(&x, &expected, desired)`
7. `atomic_thread_fence(memory_order_seq_cst)`

## Exercise 28.4 [core]

File: `ex4.s`. Compute 1 + 2 + ... + 4000000 with four threads.

- Define `struct work { long start; long end; };` (end exclusive, 16 bytes).
  Thread `i` gets `start = i*1000000 + 1`, `end = start + 1000000`.
- Each thread sums its range **in a register**, then adds its partial sum to
  a global `total` with a single `ldadd` (old value discarded: use `xzr` as
  the destination).
- `main` joins all threads and prints `total = %ld\n`.

Check:

```console
$ ./ex4
total = 8000002000000
```

Time it with `time ./ex4` and compare with `time ../examples/lse`. Why is this so much faster
than four million `ldadd`s?

## Exercise 28.5 [core]

File: `ex5.s`. Write `void atomic_max(long *p, long v)` with an
`ldxr`/`stxr` loop: if `v > *p`, store `v`; otherwise store nothing (use
`clrex`). A global `long best = 0;`.

Four threads. Thread `t` (pass `t` itself as the `void *` argument) handles
`i = t, t+4, t+8, ...` while `i < 1000000`, and calls
`atomic_max(&best, (i * 7919) % 1000003)`. `main` joins and prints
`max = %ld\n`.

Check:

```console
$ ./ex5
max = 1000002
```

Extra: write it again with `cas` instead of `ldxr`/`stxr`.

## Exercise 28.6 [core]

File: `ex6.s`. Build a spinlock from the LSE swap: `lock` swaps 1 into the
lock word with `swpa` (swap with acquire) and loops while the old value was 1;
`unlock` stores 0 with `stlr`. Four threads each do a plain `counter++` (load,
add, store) one million times under the lock.

Check, several times:

```console
$ ./ex6
counter = 4000000
```

Then change `swpa` to `swp` and `stlr` to `str`. Does it still print 4000000?
Why is it wrong anyway?

## Exercise 28.7 [stretch]

File: `ex7.s`. A lock-free stack (a "Treiber stack"), push only.

```c
struct node { struct node *next; long value; };   // 16 bytes
struct node *head = NULL;

void push(struct node **head, struct node *n) {
    struct node *old = *head;
    do {
        n->next = old;
    } while (!atomic_compare_exchange_weak(head, &old, n));   // release
}
```

Four threads; thread `t` mallocs 1000 nodes with values `t*1000 + 0` to
`t*1000 + 999` and pushes each one. Implement `push` with `casl` (compare
and swap with release: the node's fields must be visible before the node is
reachable). After joining, `main` walks the list, counts the nodes, sums the
values, frees every node, and prints `nodes = %ld, sum = %ld\n`.

Check, several times:

```console
$ ./ex7
nodes = 4000, sum = 7998000
```

## Exercise 28.8 [stretch]

File: `ex8.s`. A ticket lock: a fair lock where threads get in in the order
they arrived.

```c
struct ticket_lock { unsigned next_ticket; unsigned now_serving; };  // 8 bytes, zeroed

void ticket_lock(struct ticket_lock *t) {
    unsigned my = atomic_fetch_add(&t->next_ticket, 1);
    while (atomic_load_explicit(&t->now_serving, memory_order_acquire) != my) ;
}
void ticket_unlock(struct ticket_lock *t) {
    atomic_store_explicit(&t->now_serving, t->now_serving + 1, memory_order_release);
}
```

Use `ldadd` for the ticket, `ldar` for the wait (remember: no offset), and
`stlr` for the unlock. Four threads each do `counter++` 200000 times under
the lock.

Check, several times:

```console
$ ./ex8
counter = 800000
```
