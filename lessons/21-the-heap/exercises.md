# Lesson 21 exercises: The heap

Work in `lessons/21-the-heap/work/` (it is git-ignored). Copy the Makefile from
`examples/` into it so `make ex3` builds `ex3.s`. Run everything inside the Linux
container (`./scripts/linux-shell.sh`).

Try each exercise properly before you look at the answer. Programming solutions
are in [solutions/](solutions/) (`exN.s` for Exercise 21.N); written answers are in
[solutions/README.md](solutions/README.md). macOS versions of every solution are in
[../../apple-silicon/21-the-heap/solutions/](../../apple-silicon/21-the-heap/solutions/).

Every program must check each `malloc`/`calloc`/`realloc` result for `NULL`,
return exit status 1 if one fails, and free everything it allocated before it
returns. Check that last part with
`gcc -g -fsanitize=address exN.s -o exN_asan && ./exN_asan`: it should print
nothing extra.

## Exercise 21.1 [warm-up]

Written. How many bytes do you pass to `malloc` (or what arguments to `calloc`) for:

1. An array of 10 `long`s.
2. An array of 10 `int`s.
3. A copy of the string `"assembly"`.
4. An array of 3 `struct Vec` (24 bytes each).
5. An array of 100 pointers to `struct Person`.
6. The same as 2, but every element must start at zero (use `calloc`).

Then: a vector starts empty and doubles from a first capacity of 4, as in
`vector.s`. You push 1000 elements. How many times is `realloc` called, and what
is the final capacity?

## Exercise 21.2 [warm-up]

Written. Each snippet has exactly one bug. Name it (leak, use after free, double
free, overflow, uninitialised read, missing `NULL` check, lost block on `realloc`
failure) and fix it.

```c
// a
char *s = malloc(strlen(t));
strcpy(s, t);

// b
long *p = malloc(8 * sizeof(long));
free(p);
printf("%ld\n", p[0]);

// c
long *a = malloc(4 * sizeof(long));
if (!a) return 1;
a = realloc(a, 8 * sizeof(long));
if (!a) return 1;

// d
struct Person *p = person_new("Ada", 36);
free(p);

// e
long *sum = malloc(sizeof(long));
if (!sum) return 1;
for (int i = 0; i < 10; i++) *sum += i;

// f
long *q = malloc(16);
q[0] = 42;
```

And in assembly:

```asm
// g
    mov  x0, #64
    bl   malloc
    cbz  x0, fail
    mov  x9, x0
    adrp x0, msg
    add  x0, x0, :lo12:msg
    bl   puts
    mov  x0, x9
    bl   free
```

## Exercise 21.3 [core]

Write `ex3.s` with a function `char *my_strdup(const char *s)` that returns a
new heap copy of `s` (use `strlen` and `malloc`, but copy the bytes with your own
loop), or `NULL` if `malloc` fails. `main` duplicates `"hello"`, changes the
copy's first byte to `'J'`, prints both strings, and frees the copy.

Expected output:

```
original: hello
copy:     Jello
```

## Exercise 21.4 [core]

Write `ex4.s`. Use `calloc` to get an array of 26 `int`s (4 bytes each, all zero).
Walk the string `"hello world"`, and for each lower-case letter `c` add one to
`counts[c - 'a']`. Then print `"%c: %d\n"` for every letter whose count is not
zero, in alphabetical order, and free the array.

Hint: `sub w2, w2, #'a'` then `cmp w2, #26` / `b.hs skip` rejects every byte that
is not a lower-case letter in one unsigned comparison. Why does it also reject
bytes *below* `'a'`?

Expected output:

```
d: 1
e: 1
h: 1
l: 3
o: 2
r: 1
w: 1
```

## Exercise 21.5 [core]

Copy `examples/vector.s` to `ex5.s` and add two functions:

- `long vec_pop(struct Vec *v)`: removes and returns the last element (the caller
  guarantees `len > 0`). Do not shrink the memory.
- `long vec_sum(const struct Vec *v)`: the sum of the elements.

`main` pushes 1, 2, ..., 20, pops five times printing `popped N`, then prints the
length, the capacity, and the sum of what is left, and frees the vector.

**Predict** the last line before you run it.

Expected output:

```
popped 20
popped 19
popped 18
popped 17
popped 16
len=15 cap=32 sum=120
```

## Exercise 21.6 [core]

Write `ex6.s` with `struct Rect { long w; long h; }` (16 bytes) and:

- `struct Rect *rect_new(long w, long h)`: a heap rect, or `NULL`.
- `long rect_area(const struct Rect *r)`.
- `void free_rects(struct Rect **rs, long n)`: frees each `rs[i]`, then `rs` itself.

`main` uses `calloc` to make an array of 3 *pointers* (so the unused slots are
`NULL`), fills it with rects 2x3, 4x5 and 10x10, prints each one and the total
area, and calls `free_rects`. If a `rect_new` fails part-way, `main` must still
free what it already made (that is why `calloc`'s zeros help: `free(NULL)` is safe).

Expected output:

```
rect 0: 2 x 3 = 6
rect 1: 4 x 5 = 20
rect 2: 10 x 10 = 100
total area 126
```

## Exercise 21.7 [stretch]

Write `ex7.s`: a string builder.

```c
struct SB { char *buf; long len; long cap; };   // buf is always '\0'-terminated
int sb_append(struct SB *sb, const char *s);    // 0 on success, -1 on failure
```

`sb_append` needs `len + strlen(s) + 1` bytes. If `cap` is smaller, the new
capacity starts from `cap` (or 8 if `cap` is 0) and doubles until it is big
enough; then `realloc`. Copy `s` and its `'\0'` to `buf + len`.

`main` starts with `{ NULL, 0, 0 }`, appends `"the "`, `"quick "`, `"brown "`,
`"fox"` (keep the four string addresses in a `.quad` table in `.data`), prints
`len=%ld cap=%ld [%s]` after each append, and frees `buf`.

Expected output:

```
len=4 cap=8 [the ]
len=10 cap=16 [the quick ]
len=16 cap=32 [the quick brown ]
len=19 cap=32 [the quick brown fox]
```

## Exercise 21.8 [stretch]

Write `ex8.s`: the simplest allocator there is, a **bump allocator**.

- `arena_init` maps one 4096-byte page with the `mmap` system call (as in
  `mmap_page.s`) and stores its address in a `.bss` variable `arena`, with
  `arena_used = 0`.
- `void *bump_alloc(long n)` rounds `n` up to a multiple of 16
  (`(n + 15) & ~15`), and if it still fits, returns `arena + arena_used` and adds
  the rounded size to `arena_used`. Otherwise it returns `NULL`.
- There is no way to free one block. `arena_release` unmaps the whole page at once.

`main` allocates 10, 20, 5 and 5000 bytes, printing each block's offset from the
start of the arena (or `NULL`), then prints how much was used.

Expected output:

```
alloc 10 -> offset 0
alloc 20 -> offset 16
alloc 5 -> offset 48
alloc 5000 -> NULL
used 64 of 4096
```

Then, in a sentence or two: why does rounding to 16 matter? What would `malloc`
need that this allocator does not have, in order to support `free`?
