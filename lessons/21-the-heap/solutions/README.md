# Lesson 21 solutions

Programs: `ex3.s` to `ex8.s` in this directory. Build with `make`, run with
`./exN`. Written answers follow.

## Exercise 21.1

1. `10 * 8 = 80` bytes.
2. `10 * 4 = 40` bytes.
3. `strlen("assembly") + 1 = 9` bytes. The `+ 1` is for the `'\0'`.
4. `3 * 24 = 72` bytes.
5. `100 * 8 = 800` bytes: an array of *pointers*, and a pointer is 8 bytes no
   matter how big the struct it points to is.
6. `calloc(10, 4)`: `x0 = 10`, `x1 = 4`.

The vector: capacities go 4, 8, 16, 32, 64, 128, 256, 512, 1024. Each of those is
one `realloc` call (the first one is `realloc(NULL, 32)`, which acts like
`malloc`). So **9 calls**, final capacity **1024**.

## Exercise 21.2

- **a. Overflow.** `strlen(t)` leaves no room for the `'\0'` that `strcpy` writes.
  Fix: `malloc(strlen(t) + 1)`. (It also lacks a `NULL` check.)
- **b. Use after free.** `p[0]` is read after `free(p)`. Fix: print first, then free.
- **c. Lost block on `realloc` failure.** If `realloc` fails, `a` becomes `NULL`
  and the original 4-element block leaks. Fix:
  `long *t = realloc(a, ...); if (!t) { free(a); return 1; } a = t;`
- **d. Leak.** `free(p)` frees the struct but not `p->name`, which the struct
  owned. Fix: `person_free(p)`, which frees the name first.
- **e. Uninitialised read.** `*sum` starts as garbage, because `malloc` does not
  zero memory. Fix: `*sum = 0;` first, or use `calloc(1, sizeof(long))`.
- **f. Missing `NULL` check.** If `malloc` fails, `q[0] = 42` writes to address 0
  and crashes. Fix: `if (!q) return 1;`.
- **g. Pointer in a caller-saved register.** `x9` holds the block across
  `bl puts`, and `puts` may overwrite `x9`, so `free` gets a garbage address (it
  will usually abort with `free(): invalid pointer`, or leak). Fix: keep it in
  `x19` and save/restore `x19` in the prologue/epilogue.

## Exercise 21.4 (the question in the hint)

After `sub w2, w2, #'a'`, a byte *below* `'a'` (for example the space, 32) gives a
negative result: 32 - 97 = -65. As an unsigned 32-bit number, -65 is about 4.29
billion, which is far above 26, so `b.hs` (unsigned `>=`) skips it. One unsigned
comparison checks both ends of the range.

## Exercise 21.8 (the questions)

- **Why round to 16?** The ABI promises that `malloc` returns memory suitably
  aligned for any type, which on AArch64 means 16 bytes. If one block were 10
  bytes long and the next started right after it, the next block would start at
  an address that is not even 8-aligned, and storing a `long` there would be a
  misaligned access (slow, and not allowed at all for some instructions).
- **What `free` would need.** The allocator must know how big each block is (so
  `malloc` keeps a size header just before every block), and it must remember
  which blocks are free so it can reuse them (a "free list" of available
  blocks). A bump allocator keeps neither; it can only throw the whole arena away
  at once. That is still useful: compilers and games use exactly this for data
  that all dies at the same moment.
