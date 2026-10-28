# Lesson 28 solutions

Programs: `ex4.s` to `ex8.s`. Build with `make` (every program is linked with
`-pthread`) and run each one several times. Written answers are below.

## Exercise 28.1

(a) The final value is **1 or 2**.

2: the threads do not overlap.

| Step | Thread A | Thread B | counter |
|------|----------|----------|---------|
| 1 | `ldr` gets 0 | | 0 |
| 2 | `add` makes 1 | | 0 |
| 3 | `str` writes 1 | | 1 |
| 4 | | `ldr` gets 1 | 1 |
| 5 | | `add` makes 2, `str` writes 2 | 2 |

1: both load before either stores.

| Step | Thread A | Thread B | counter |
|------|----------|----------|---------|
| 1 | `ldr` gets 0 | | 0 |
| 2 | | `ldr` gets 0 | 0 |
| 3 | `add`, `str` writes 1 | | 1 |
| 4 | | `add`, `str` writes 1 | 1 |

It can never be 0 (both threads store 1 or more) or more than 2.

(b) Some lines could show `result = 0`, or even a struct the thread had not
finished writing, because the threads might not have run yet. It could
*happen* to print the right thing if all threads finished in time, but
nothing *guarantees* it: only `pthread_join` (or some other synchronisation)
makes a thread's writes visible to `main`.

## Exercise 28.2

(a) 0 after success, 1 after failure.

(b) The old value, or whatever another thread has written since. A failed
`stxr` writes nothing.

(c) The status register must not be the same as the register being stored
(or the address register). The architecture calls it "unpredictable": the
assembler rejects it (clang) or warns (GNU as).

(d) The call does memory accesses of its own (it pushes a frame, `printf`
touches buffers, it may make a system call). Any of that may clear the
exclusive monitor, so the `stxr` may fail **every** time and the loop spins
forever. Keep `ldxr`...`stxr` to a few register instructions.

(e) Atomicity is all a counter needs: every increment happens exactly once.
Ordering only matters for *other* data that one thread publishes to another,
and here the only other thread that looks is `main`, after `pthread_join`,
which already orders everything.

## Exercise 28.3

| C11 | With LSE | Without LSE |
|-----|----------|-------------|
| `atomic_fetch_add(&x, 1)` | `ldaddal` | `ldaxr` / `add` / `stlxr` / `cbnz` loop |
| `..._explicit(..., relaxed)` | `ldadd` | `ldxr` / `add` / `stxr` / `cbnz` loop |
| `atomic_load(&x)` | `ldar` | `ldar` |
| `atomic_store(&x, v)` | `stlr` | `stlr` |
| `atomic_exchange(&x, v)` | `swpal` | `ldaxr` / `stlxr` / `cbnz` loop |
| `atomic_compare_exchange_strong` | `casal`, then `cmp` + `cset` | `ldaxr` / `cmp` / `b.ne` / `stlxr` / `cbnz` loop |
| `atomic_thread_fence(seq_cst)` | `dmb ish` | `dmb ish` |

With plain `gcc -O2` (no `-march`) the read-modify-write operations become
calls such as `bl __aarch64_ldadd8_acq_rel` (outline atomics), which pick one
of the two forms at run time.

## Exercise 28.4

`ex4.s`. It is much faster than `lse` because each thread touches
shared memory **once**. The four million additions happen in registers, so
the cores never fight over the counter's cache line. "Work privately, combine
once" is the most important trick in parallel programming.

## Exercise 28.5

`ex5.s`. The `cas` version of `atomic_max`:

```asm
atomic_max:                         // x0 = p, x1 = v
    ldr     x2, [x0]                // guess the current value
am_retry:
    cmp     x2, x1
    b.ge    am_done                 // already >= v
    mov     x3, x2
    cas     x3, x1, [x0]            // if (*p == x3) *p = v; x3 = old *p
    cmp     x3, x2
    b.eq    am_done                 // our store happened
    mov     x2, x3                  // someone changed it: retry with their value
    b       am_retry
am_done:
    ret
```

(Or, with LSE, simply `ldsmax x1, xzr, [x0]`: signed atomic max in one
instruction.)

## Exercise 28.6

`ex6.s`. With `swp` and `str` it *usually* still prints 4000000, which is the
dangerous part. In one test in the container, four runs printed 4000000 and
the fifth printed 3999978. It is wrong every time, not just that time: without
acquire, loads in the critical section may be performed before the lock is
really ours, and without release, the stores in the critical section may
become visible after the lock looks free. Another thread could then read an
old `counter`. Testing cannot prove ordering code correct; reasoning can.

## Exercise 28.7

`ex7.s`. `casl` (release) is needed so that `n->next` and `n->value` are
visible before any other thread can reach `n` through `head`. A pop operation
is much harder (the "ABA problem": a node can be popped, freed, reallocated,
and pushed back between your load of `head` and your `cas`), which is why
this exercise is push only.

## Exercise 28.8

`ex8.s`. Note that `ticket_unlock` reads `now_serving` with a plain `ldr`: only
the lock holder ever writes it, so the holder's own last write is the current
value. A ticket lock is fair (first come, first served) but behaves very
badly if there are more threads than cores: if the thread whose turn it is
gets descheduled, everyone behind it waits.
