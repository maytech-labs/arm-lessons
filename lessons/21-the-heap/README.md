# Lesson 21: The heap

## Goals

After this lesson you can:

- Say where a value lives (static data, the stack, or the heap) and how long it lives.
- Call `malloc`, `calloc`, `realloc`, and `free` from assembly, and check for `NULL`.
- Work out the byte count to ask for (`n * sizeof(T)`) with `.equ` and shifts.
- Build a growable array (a "vector") that doubles its capacity with `realloc`.
- Allocate structs on the heap, with a constructor and a destructor, and say who owns them.
- Recognise the classic memory bugs (leak, use-after-free, double free, overflow)
  and what each one looks like when it happens.
- Explain, roughly, how `malloc` gets memory from the kernel (`brk` and `mmap`).

## Before you start

You need:

- [Lesson 13](../13-the-stack/): the stack, and why stack memory disappears when a function returns.
- [Lesson 15](../15-calling-convention/): callee-saved registers. Every pointer you get
  from `malloc` must survive later calls, so it lives in `x19`-`x28`.
- [Lesson 16](../16-calling-c/): calling libc functions with `bl`.
- [Lesson 19](../19-structs-and-unions/): struct offsets with `.equ`.
- [Lesson 20](../20-symbols-and-sections/): `.data`, `.bss`, `.rodata`.

All examples are in [examples/](examples/). Build them inside the Linux container:

```console
$ ./scripts/linux-shell.sh
# cd lessons/21-the-heap/examples
# make
```

## 1. Three places memory can live

So far your data has lived in two places.

**Static data** (`.data`, `.bss`, `.rodata`, lesson 20). The size is fixed when you
assemble the program. It exists from the moment the program starts until it ends.

**The stack** (lesson 13). Each function call reserves some bytes by moving `sp`
down, and gives them back by moving `sp` up when it returns. Fast and automatic,
but a local variable *dies* when its function returns.

Neither of these can answer a very common question: "I need room for `n` items,
where `n` is only known at run time, and I need it to outlive the function that
made it." That is what the **heap** is for.

| | Static data | Stack | Heap |
|-|-------------|-------|------|
| C example | `static long count;` | `long x;` inside a function | `long *p = malloc(8);` |
| Size decided | when you assemble | when you write the function | at run time |
| Lifetime | the whole program | until the function returns | until you call `free` |
| Who cleans up | nobody needs to | `ret` (moving `sp` back) | **you** |

The heap is just a large region of memory that the C library manages for you.
You ask for a block of `n` bytes with `malloc(n)`; it gives you the address of a
block nobody else is using. When you are finished, you hand the block back with
`free`. Between those two calls the block is yours, whatever function you are in.

Let's look at where the three regions are. [addresses.s](examples/addresses.s)
prints the address of a global, of a block from `malloc`, and of a local on the stack.

```c
long counter = 7;
int main(void) {
    long local;
    printf("static data: %p\n", &counter);
    long *p = malloc(16);
    if (p == NULL) return 1;
    printf("heap:        %p\n", p);
    printf("stack:       %p\n", &local);
    free(p);
    return 0;
}
```

**Predict:** which two addresses will be close to each other?

```console
$ ./addresses
static data: 0xaaaad5c20010
heap:        0xaaaaf9e8a2a0
stack:       0xffffd3b6f2d8
```

Your numbers will differ (the kernel randomises the layout on every run, a
defence called ASLR), but the pattern will not: static data and the heap sit low,
near your program, and the stack is far above them, near the top of the address
space. The heap grows *up* from just after your program; the stack grows *down*
from the top.

The only new things in that program are the calls `bl malloc` and `bl free`.
The interesting part is what you do with the result.

## 2. `malloc` and `free`

The C prototypes are:

```c
void *malloc(size_t size);   // size in BYTES; returns an address or NULL
void  free(void *p);         // p must have come from malloc/calloc/realloc (or be NULL)
```

By the calling convention you already know (lesson 15):

| C | Register |
|---|----------|
| `size` argument | `x0` |
| return value (the address) | `x0` |
| `p` argument to `free` | `x0` |

`malloc` is an ordinary function, so it may destroy every caller-saved register
(`x0`-`x17`). Keep the pointer it returns in a callee-saved register (`x19`-`x28`)
or in your stack frame.

### Counting bytes: `sizeof` arithmetic

`malloc` counts **bytes**, not elements. In C you write `malloc(5 * sizeof(long))`
and the compiler multiplies for you. In assembly you multiply. When the count is
a constant, let the assembler do it with `.equ`:

```asm
    .equ COUNT, 5
    .equ LONG_SIZE, 8
    mov  x0, #(COUNT * LONG_SIZE)   // 40, computed by the assembler
    bl   malloc
```

When the count is in a register, multiply at run time. Element sizes are usually
powers of two, so a shift does it:

| C | Assembly (count in `x1`) |
|---|--------------------------|
| `malloc(n * sizeof(long))` | `lsl x0, x1, #3` |
| `malloc(n * sizeof(int))` | `lsl x0, x1, #2` |
| `malloc(n * sizeof(char))` | `mov x0, x1` |
| `malloc(n * sizeof(struct Vec))` (24 bytes) | `mov x2, #24` then `mul x0, x1, x2` |
| `malloc(strlen(s) + 1)` | `bl strlen` then `add x0, x0, #1` |

The last row is the one everyone forgets: a C string needs one more byte than its
length, for the `'\0'`.

### Checking for `NULL`

`malloc` returns `NULL` (address 0) when it cannot give you the memory. Using that
address crashes your program. Always check, with the instruction made for it:

```asm
    bl   malloc
    cbz  x0, main_fail          // if (p == NULL) goto fail;
    mov  x19, x0                // keep p safe across later calls
```

On a modern desktop `malloc` almost never fails for small requests, which is
exactly why unchecked code survives testing and then crashes on someone else's
machine. Check every time.

### Example: an array on the heap

[malloc_array.s](examples/malloc_array.s) is this C program:

```c
long *a = malloc(5 * sizeof(long));
if (a == NULL) return 1;
for (long i = 0; i < 5; i++) a[i] = i * i;
for (long i = 0; i < 5; i++) printf("a[%ld] = %ld\n", i, a[i]);
free(a);
return 0;
```

Once you have the address, a heap array is used exactly like the arrays of
lesson 12: `str x1, [x19, x20, lsl #3]` stores to `a[i]`. Memory is memory; the
CPU does not know or care that it came from `malloc`.

**Predict** the output, then run it:

```console
$ ./malloc_array
a[0] = 0
a[1] = 1
a[2] = 4
a[3] = 9
a[4] = 16
```

`free(a)` at the end gives the block back. After that line, `a` still holds the
same number, but the memory it points to is no longer yours. Section 6 shows what
happens if you forget that.

## 3. `calloc` and `realloc`

Two more functions round out the family.

```c
void *calloc(size_t n, size_t size);   // n * size bytes, all set to zero
void *realloc(void *p, size_t size);   // resize a block, keeping its contents
```

**`calloc`** takes the count and the element size as two arguments (`x0`, `x1`),
multiplies them for you (and returns `NULL` if the product would overflow), and
fills the block with zeros. Memory from `malloc` is *not* zeroed: it holds
whatever was there before.

**`realloc`** changes the size of a block you already own. It may grow the block
in place, or it may allocate a new block, copy your bytes into it, free the old
one, and return the new address. Either way:

- The return value is the address to use from now on. The old address may be dead.
- The first `min(old size, new size)` bytes are preserved. New bytes are not zeroed.
- On failure it returns `NULL` and **leaves the old block alone**: you still own it.
- `realloc(NULL, n)` behaves like `malloc(n)`. That is handy for "start empty, grow later".

That third point creates the most common `realloc` bug. In C:

```c
p = realloc(p, new_size);     // WRONG: if realloc fails, p becomes NULL and the
                              // old block is lost forever (a leak)

long *tmp = realloc(p, new_size);   // RIGHT
if (tmp == NULL) { free(p); return 1; }
p = tmp;
```

In assembly the "right" version comes naturally: keep `p` in `x19`, and only
overwrite `x19` after you have checked the result.

```asm
    mov  x0, x19                    // old block
    mov  x1, #(8 * 8)               // new size in bytes
    bl   realloc
    cbz  x0, main_realloc_fail      // x19 is still valid here
    mov  x19, x0                    // only now replace p
```

[calloc_realloc.s](examples/calloc_realloc.s) uses all of this: `calloc` four
longs, print them, fill them, `realloc` to eight, print the first four (they were
copied), fill the rest, print all eight.

**Predict** each line before you run it.

```console
$ ./calloc_realloc
after calloc: 0 0 0 0
after fill: 1 2 3 4
after realloc: 1 2 3 4
after second fill: 1 2 3 4 5 6 7 8
```

Notice that the "after realloc" line prints only four elements. Elements 4 to 7
exist but hold garbage until we fill them; printing them would print whatever
happened to be in that memory.

## 4. A growable array (a vector)

Real programs rarely know in advance how many items they will have: lines in a
file, words typed by the user. The standard answer is a **growable array**: an
array on the heap plus two counts.

```c
struct Vec {
    long *data;   // offset 0: the heap array (NULL when empty)
    long  len;    // offset 8: how many elements are in use
    long  cap;    // offset 16: how many elements fit before we must grow
};                // sizeof = 24
```

Pushing an element is easy while `len < cap`. When `len == cap`, the array is
full, and we `realloc` it to twice its capacity:

```c
int vec_push(struct Vec *v, long x) {
    if (v->len == v->cap) {
        long newcap = v->cap ? v->cap * 2 : 4;
        long *p = realloc(v->data, newcap * sizeof(long));
        if (p == NULL) return -1;     // v is unchanged and still valid
        v->data = p;
        v->cap = newcap;
    }
    v->data[v->len++] = x;
    return 0;
}
```

Why double, rather than grow by one? Each `realloc` may copy the whole array.
Growing by one would copy 1 + 2 + 3 + ... + n elements: about n²/2. Doubling
copies 4 + 8 + 16 + ... + n elements: less than 2n in total. Pushing a million
elements costs about twenty `realloc` calls instead of a million.

The assembly version is [vector.s](examples/vector.s). The struct offsets are
`.equ`s, as in lesson 19:

```asm
    .equ VEC_DATA, 0
    .equ VEC_LEN,  8
    .equ VEC_CAP,  16
    .equ VEC_SIZE, 24
```

Here is the "do we need to grow?" part of `vec_push`. `x19` holds `v`:

```asm
    ldr  x2, [x19, #VEC_LEN]
    ldr  x3, [x19, #VEC_CAP]
    cmp  x2, x3
    b.ne vec_push_store             // room left: no need to grow

    // newcap = cap ? cap * 2 : VEC_FIRST_CAP
    lsl  x21, x3, #1
    mov  x4, #VEC_FIRST_CAP
    cmp  x21, #0
    csel x21, x4, x21, eq

    // p = realloc(v->data, newcap * sizeof(long));
    ldr  x0, [x19, #VEC_DATA]
    lsl  x1, x21, #3
    bl   realloc
    cbz  x0, vec_push_fail          // old data is untouched and still owned by v
    str  x0, [x19, #VEC_DATA]       // v->data = p;
    str  x21, [x19, #VEC_CAP]       // v->cap = newcap;
```

Two details worth slowing down for:

- `newcap` is needed *after* the call to `realloc`, so it lives in `x21`, a
  callee-saved register that `vec_push` saves in its prologue. If you put it in
  `x3` it would be gone when `realloc` returns.
- The very first push has `data == NULL` and `cap == 0`. `realloc(NULL, 32)` acts
  like `malloc(32)`, so the empty case needs no special code.

The `struct Vec` itself lives in `main`'s stack frame at `[sp, #32]`; only the
array it points to is on the heap. `main` passes `&v` as `add x0, sp, #32`.

`main` pushes the squares 1, 4, 9, ..., 100 and prints `len` and `cap` after each push.

**Predict:** after which pushes does `cap` change, and to what?

```console
$ ./vector
push 1: len=1 cap=4
push 4: len=2 cap=4
push 9: len=3 cap=4
push 16: len=4 cap=4
push 25: len=5 cap=8
push 36: len=6 cap=8
push 49: len=7 cap=8
push 64: len=8 cap=8
push 81: len=9 cap=16
push 100: len=10 cap=16
contents: 1 4 9 16 25 36 49 64 81 100
```

`vec_free` frees `data` and resets the struct to empty (`vec_init`), so a stale
`data` pointer is not left lying around. `free(NULL)` is allowed and does
nothing, so freeing an empty vector is safe.

## 5. Structs on the heap, and ownership

The other big use of the heap is objects whose lifetime does not match any one
function: create in one place, use in many, destroy somewhere else. In C:

```c
struct Person { char *name; long age; };     // 16 bytes

struct Person *person_new(const char *name, long age) {
    struct Person *p = malloc(sizeof(struct Person));
    if (p == NULL) return NULL;
    size_t n = strlen(name) + 1;
    p->name = malloc(n);
    if (p->name == NULL) { free(p); return NULL; }
    memcpy(p->name, name, n);
    p->age = age;
    return p;
}

void person_free(struct Person *p) {
    if (p == NULL) return;
    free(p->name);
    free(p);
}
```

The important word here is **ownership**. Every heap block has exactly one owner:
the piece of code responsible for freeing it, exactly once. C has no way to write
this down, so you write it in comments:

- `person_new` returns a block the **caller** owns. The caller must eventually
  pass it to `person_free`.
- Each `Person` owns its `name` (its own copy, not the caller's string). That is
  why `person_free` frees `p->name` *before* `p`: after `free(p)` you may not
  read `p->name` any more.
- If the second `malloc` fails, `person_new` frees the first block before
  returning `NULL`. Otherwise half a person would leak.

Pairs like `person_new`/`person_free` (a constructor and a destructor) are how
C programs keep ownership manageable. You will use the same shape for list nodes
and tree nodes in lesson 22.

[person.s](examples/person.s) is the assembly version. The constructor keeps
`name`, `age`, the new block, and the length in `x19`-`x22`, because each of them
is needed after a call. `memcpy(dst, src, n)` takes its arguments in `x0`, `x1`,
`x2`, and the destination is already in `x0` because `malloc` just returned it:

```asm
    mov  x0, x22                    // p->name = malloc(n);
    bl   malloc
    cbz  x0, person_new_fail
    str  x0, [x21, #PERSON_NAME]

    mov  x1, x19                    // memcpy(p->name, name, n);   x0 is p->name
    mov  x2, x22
    bl   memcpy
```

`main` creates two people, has a birthday, prints, and frees both.

```console
$ ./person
Ada is 36
Linus is 28
Linus is 29
```

## 6. Memory bugs and how they show up

The heap gives you power and no safety net. These are the bugs every C and
assembly programmer meets. Learn their names; you will need them when debugging.

| Bug | C | What usually happens |
|-----|---|----------------------|
| **Leak** | lose the last pointer to a block without freeing it | nothing visible; memory use grows until the program ends |
| **Use after free** | `free(p); x = *p;` | wrong values, much later and somewhere else; sometimes a crash |
| **Double free** | `free(p); free(p);` | the C library detects it and kills the program |
| **Buffer overflow** | `a = malloc(5*8); a[5] = 1;` | corrupts the next block or the allocator's own bookkeeping; a crash later, often inside `malloc` or `free` |
| **Uninitialised read** | `p = malloc(8); x = *p;` | garbage values, different from run to run |
| **Missing `NULL` check** | `p = malloc(n); *p = 1;` | segmentation fault, but only when memory runs out |
| **Freeing a non-heap pointer** | `free(&local);` or `free(p + 1)` | the C library aborts the program |

Why do overflows corrupt "the allocator's own bookkeeping"? Because `malloc`
stores information about each block (its size, at least) in the bytes just before
the address it gives you. Write past the end of your block and you overwrite the
header of the next one. Nothing happens at that moment. The crash comes later,
when `malloc` or `free` reads the damaged header, which makes these bugs hard to
find.

### A double free

[double_free.s](examples/double_free.s) frees the same block twice. The modern
glibc allocator keeps a small cache of freed blocks (the "tcache") and notices
that the block is already in it.

```console
$ ./double_free
freed once
free(): double free detected in tcache 2
Aborted (core dumped)
$ echo $?
134
```

134 is 128 + 6: the program was killed by signal 6, `SIGABRT`. The C library
called `abort()` on purpose because continuing would be worse. "core dumped"
means the kernel saved a snapshot of the crashed program's memory; if a file
named `core` appears in the directory, that is it (gdb can open it), and you can
delete it.

The program calls `fflush(NULL)` before the bad `free`. `puts` does not always
write immediately (output is buffered, lesson 25), and `abort` throws away
unwritten output. Without the flush, "freed once" can vanish when the output goes
to a pipe or a file, which is very confusing when you are trying to find where a
program died.

### A leak, and a tool that finds it

[leak.s](examples/leak.s) mallocs three blocks in a loop but keeps only the last
pointer:

```c
long *p = NULL;
for (int i = 0; i < 3; i++) p = malloc(100);   // BUG: the old p is lost
free(p);
```

It runs fine:

```console
$ ./leak
allocated 3 blocks, freed 1
```

Leaks never crash anything; that is what makes them dangerous in programs that
run for days. To see it, build the same file with **AddressSanitizer**, a checker
built into gcc that replaces `malloc` and `free` with careful versions:

```console
$ gcc -g -fsanitize=address leak.s -o leak_asan
$ ./leak_asan
allocated 3 blocks, freed 1

=================================================================
==61==ERROR: LeakSanitizer: detected memory leaks

Direct leak of 200 byte(s) in 2 object(s) allocated from:
    #0 0xf1560c97b734 in __interceptor_malloc ...
    #1 0xc0dd85d308b4  (/work/lessons/21-the-heap/examples/leak_asan+0x8b4)
    ...
SUMMARY: AddressSanitizer: 200 byte(s) leaked in 2 allocation(s).
$ rm leak_asan
```

Try the same with `double_free.s`: it reports `attempting double-free` with a
stack trace. One limit: AddressSanitizer finds overflows by adding checks to code
the *compiler* generates. Your hand-written loads and stores get no checks, so it
catches leaks and bad `free`s in assembly programs, but not overflows inside them.

## 7. Where `malloc` gets its memory

`malloc` is not magic and not part of the CPU. It is ordinary code in the C
library. It gets large chunks of memory from the kernel with system calls, and
cuts them into the small blocks you ask for. On Linux there are two such calls:

- **`brk`** moves the end of the heap region (the "program break") upward. glibc
  uses this for normal small requests: it grows the heap by about 132 KiB at a
  time and then hands out pieces.
- **`mmap`** asks for a fresh region of whole pages (4096 bytes each) anywhere in
  the address space. glibc uses it for big requests (128 KiB or more), and
  gives such blocks straight back to the kernel when you `free` them.

You can watch this with `strace`, which prints every system call a program makes:

```console
$ strace ./vector 2>&1 >/dev/null | grep brk
brk(NULL)                               = 0xc961de53f000
brk(NULL)                               = 0xc961de53f000
brk(0xc961de560000)                     = 0xc961de560000
```

`brk(NULL)` asks "where does the heap end now?". The last line moves the end up by
`0x21000` bytes (132 KiB). All ten pushes and all four `realloc`s in `vector` came
out of that one chunk.

You can call `mmap` yourself. Its C prototype has six arguments, and the raw
system call (number 222 on Linux) takes them in `x0`-`x5`, exactly like a function:

```c
void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
page = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
```

- `addr` = `NULL`: let the kernel choose where.
- `prot`: the page may be read and written (not executed).
- `MAP_ANONYMOUS`: not backed by a file, just fresh zeroed memory. `MAP_PRIVATE`:
  not shared with other processes.
- `fd` = -1 and `offset` = 0: no file.

[mmap_page.s](examples/mmap_page.s) maps one page, copies a string into it, prints
it, and gives the page back with `munmap` (system call 215). Like every Linux
system call, a failure comes back as a negative number in `x0` (lesson 05), and a
user-space address is never negative, so `tbnz x0, #63, main_fail` checks for it.

```console
$ ./mmap_page
got 4096 bytes from mmap
hello from a fresh page
page returned with munmap
```

A memory allocator is "just" a program that calls `mmap` (or `brk`) now and then,
and keeps track of which pieces of those pages are in use. Exercise 21.8 asks you
to write the simplest possible one.

## C to assembly

| C | AArch64 (Linux) |
|---|-----------------|
| `p = malloc(n);` | `mov x0, n` / `bl malloc` / result in `x0` |
| `if (p == NULL) goto fail;` | `cbz x0, fail` |
| `malloc(5 * sizeof(long))` | `mov x0, #(5 * 8)` |
| `malloc(n * sizeof(long))` | `lsl x0, x1, #3` / `bl malloc` |
| `malloc(strlen(s) + 1)` | `bl strlen` / `add x0, x0, #1` / `bl malloc` |
| `p = calloc(n, size);` | `mov x0, n` / `mov x1, size` / `bl calloc` |
| `tmp = realloc(p, size);` | `mov x0, x19` / `mov x1, size` / `bl realloc` |
| `if (!tmp) {...} p = tmp;` | `cbz x0, fail` / `mov x19, x0` |
| `free(p);` | `mov x0, x19` / `bl free` |
| `v->data[v->len++] = x;` | `ldr x0, [v, #DATA]` / `ldr x2, [v, #LEN]` / `str x, [x0, x2, lsl #3]` / `add x2, x2, #1` / `str x2, [v, #LEN]` |
| `struct Vec v;` (local) / `&v` | reserve 24+ bytes in the frame / `add x0, sp, #off` |
| `p = mmap(NULL, 4096, ...);` | `x0`-`x5` = arguments, `mov x8, #222` / `svc #0` |

## Common mistakes

- **Forgetting that `malloc` counts bytes.** `mov x0, #5` / `bl malloc` gives you
  5 bytes, not 5 longs. Storing 5 longs then overflows by 35 bytes, and the crash
  comes later, somewhere else.
- **Keeping the pointer in a caller-saved register.** `bl malloc` / `mov x9, x0` /
  `bl printf` / `ldr x1, [x9]`: `printf` was allowed to destroy `x9`. Usually a
  segmentation fault. Use `x19`-`x28` (and save them in your prologue).
- **Not checking for `NULL`.** Works on your machine; crashes on a busy one.
- **`p = realloc(p, n)`.** On failure you lose `p` and leak the block. Check the
  result before overwriting your only copy.
- **Using the old address after `realloc`.** If `realloc` moved the block, the old
  address is freed memory (use after free). Always reload `v->data` after growing.
- **Forgetting the `+ 1` for a string's `'\0'`.** One byte of overflow. Often
  harmless for months, then not.
- **Freeing in the wrong order.** `free(p); free(p->name);` reads `p->name` from
  memory you no longer own. Free the parts, then the whole.
- **Freeing twice, or freeing something that did not come from `malloc`.**
  glibc aborts: `free(): double free detected` or `free(): invalid pointer`,
  exit status 134.
- **Expecting `malloc` memory to be zero.** Only `calloc` (and fresh `mmap` pages)
  are zeroed. A program that "works" because the memory happened to be zero breaks
  when it runs longer.

## Recap

- Static data lives for the whole program, the stack until the function returns,
  the heap until you call `free`.
- `malloc(bytes)` returns an address in `x0`, or `NULL`; check it with `cbz`.
- You do the `sizeof` arithmetic: `.equ` constants for fixed sizes, `lsl` or `mul`
  for run-time counts, `+ 1` for strings.
- `calloc(n, size)` zeroes and checks the multiplication; `realloc` may move the
  block, keeps the old contents, and leaves the old block alone on failure.
- A growable array is `{ data, len, cap }`; doubling the capacity keeps the total
  copying under 2n.
- Every heap block has one owner who frees it exactly once. Write it in comments,
  and pair every constructor with a destructor.
- Leaks are silent, double frees abort, overflows and use-after-free corrupt
  memory and crash later. AddressSanitizer (`-fsanitize=address`) finds leaks and
  bad frees, even in assembly programs.
- `malloc` is library code that gets big chunks from the kernel with `brk` and
  `mmap` and cuts them into small blocks.

## Homework

Do the exercises in [exercises.md](exercises.md). Then read the macOS companion,
[../../apple-silicon/21-the-heap/](../../apple-silicon/21-the-heap/).
