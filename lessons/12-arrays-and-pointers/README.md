# Lesson 12: Arrays and pointers

## Goals

After this lesson you can:

- Lay out an array in memory and find any element's address.
- Explain why `a[i]` is `*(a + i)`, and what "scaling" means.
- Walk an array either with an index or with a moving pointer.
- Compute a pointer difference (`p - a`) and `sizeof`.
- Store and index a 2D array in row-major order.
- Search (linearly and by binary search), find a maximum, reverse, and sort.

## Before you start

You need lesson 11: loads and stores of every size, the addressing modes, and
the "print a number" block. Every example here prints its result with that
same block (copied into each file, since we do not have functions until
lesson 14). It prints `x19` in decimal followed by the character in `w20`.

```console
# cd lessons/12-arrays-and-pointers/linux/examples && make
```

## An array is just consecutive memory

```c
int a[8] = {3, 1, 4, 1, 5, 9, 2, 6};
```

```asm
    .data
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
```

Eight 4-byte words, one after the other. If `a` is at address `A`:

| Element | Address |
|---------|---------|
| `a[0]` | `A + 0` |
| `a[1]` | `A + 4` |
| `a[2]` | `A + 8` |
| `a[i]` | `A + 4*i` |

The array has no length stored anywhere, and no type. It is 32 bytes of memory
with a label at the front. The **4** comes from you knowing these are `int`s.
For an array of `long` (`.quad`) it would be 8; for `char` (`.byte`) it would
be 1. That multiplier is the **element size**, and multiplying the index by it
is called **scaling**.

## `a[i]`: indexing with a scaled register

The register-offset addressing mode from lesson 11 does the scaling for you:

```asm
    ldrsw x11, [x9, x10, lsl #2]    // x11 = a[i]: address a + i*4
```

`lsl #2` multiplies the index by 4. The shift must match the element size:

| Type | Size | Shift | Load |
|------|------|-------|------|
| `char` | 1 | none | `ldrb` / `ldrsb` |
| `short` | 2 | `lsl #1` | `ldrh` / `ldrsh` |
| `int` | 4 | `lsl #2` | `ldr w` / `ldrsw` |
| `long`, pointer | 8 | `lsl #3` | `ldr x` |

(The only shifts allowed in this addressing mode are 0 and the one matching the
access size. The assembler rejects anything else.)

`examples/sum_index.s` adds up the array:

```asm
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a (address of a[0])
    mov x10, #0                 // x10 = i
    mov x19, #0                 // x19 = sum
    mov x15, #N                 // x15 = N
loop:
    cmp x10, x15
    b.ge done                   // while (i < N)
    ldrsw x11, [x9, x10, lsl #2]    // x11 = a[i]: address a + i*4
    add x19, x19, x11           // sum += a[i]
    add x10, x10, #1            // i++
    b loop
```

Why `ldrsw` and not `ldr w11`? Because `sum` is a 64-bit `long` and the
elements are signed `int`s. `ldrsw` sign-extends each one to 64 bits so a
negative element subtracts properly (lesson 11).

### Letting the assembler count: `sizeof`

```asm
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
    .equ N, (. - a) / 4         // number of elements: bytes / sizeof(int)
```

`. - a` is the array's size in bytes (C's `sizeof a`), and dividing by the
element size gives the number of elements, exactly like C's
`sizeof a / sizeof a[0]`. `examples/sizeof.s` prints both for two arrays:
`32 8 40 5`.

## `*p++`: walking a pointer

C lets you write the same loop with a pointer instead of an index:

```c
for (int *p = a, *end = a + 8; p != end; p++)
    sum += *p;
```

`examples/sum_pointer.s`:

```asm
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = p = a
    mov x10, #N * 4             // x10 = sizeof a = N * 4 bytes
    add x10, x9, x10            // x10 = end = a + N (N*4 bytes along)
    mov x19, #0
loop:
    cmp x9, x10
    b.eq done                   // while (p != end)
    ldrsw x11, [x9], #4         // x11 = *p, then p++ (4 bytes)
    add x19, x19, x11
    b loop
```

Two things to notice:

1. **C's pointer arithmetic is scaled; the CPU's is not.** In C, `p++` on an
   `int *` moves 4 bytes and `a + 8` means 8 *elements* along. In assembly, you
   add the byte counts yourself: `#4`, and `N * 4`.
2. **The post-index mode `[x9], #4` is `*p++`** in one instruction: load from
   `p`, then add 4 to `p`.

`end` points one past the last element. That address is never read; it is
only compared against. C allows exactly this.

Index or pointer? Both compile to similar code. The pointer version saves the
counter register; the index version is easier when you need `i` itself, or
several arrays at the same index.

## Pointer difference

If `p` points at an element, which index is it? `p - a` in C, which is the
byte distance **divided by the element size**. `examples/search.s` finds the
first 5:

```asm
found:
    sub x19, x10, x9            // bytes between p and a
    lsr x19, x19, #2            // / sizeof(int): index = p - a
```

```console
# ./search; echo $?
4
4
```

## Pointers are unsigned

Addresses are unsigned numbers. When you compare two pointers with `<` or `>`,
use the unsigned conditions (`b.lo`, `b.hs`, ...) from lesson 09.
`examples/reverse.s` swaps elements from both ends until the pointers meet:

```c
int *lo = a, *hi = a + 8 - 1;
while (lo < hi) {
    int t = *lo; *lo = *hi; *hi = t;
    lo++; hi--;
}
```

```asm
swap:
    cmp x10, x11
    b.hs reversed               // while (lo < hi): pointers are unsigned
    ldr w12, [x10]              // w12 = *lo
    ldr w13, [x11]              // w13 = *hi
    str w13, [x10], #4          // *lo = old *hi, lo++
    str w12, [x11], #-4         // *hi = old *lo, hi--
    b swap
```

Post-index with `#-4` moves a pointer backwards.

## Finding the maximum

`examples/maxmin.s` scans an array of `long`s (`.quad`, so `lsl #3`) and keeps
the running maximum and minimum with `csel` from lesson 10:

```asm
    ldr x11, [x9, x10, lsl #3]  // x11 = a[i]: address a + i*8
    cmp x11, x21
    csel x21, x11, x21, gt      // max = a[i] > max ? a[i] : max   (signed)
    cmp x11, x22
    csel x22, x11, x22, lt      // min = a[i] < min ? a[i] : min
```

Start `max` and `min` at `a[0]`, not at 0: an array of negative numbers has a
maximum below 0.

## 2D arrays: row-major order

```c
int m[3][4] = { { 1,  2,  3,  4},
                { 5,  6,  7,  8},
                { 9, 10, 11, 12} };
```

Memory is one-dimensional, so C stores the rows one after another: all of row
0, then all of row 1, and so on. That is **row-major order**. Element
`m[r][c]` is element number `r * COLS + c` from the start:

```
index:   0  1  2  3 | 4  5  6  7 | 8  9 10 11
value:   1  2  3  4 | 5  6  7  8 | 9 10 11 12
         row 0        row 1        row 2
```

`examples/matrix.s` reads `m[1][2]` with a `madd`:

```asm
    mov x10, #1                 // r = 1
    mov x11, #2                 // c = 2
    mov x13, #COLS
    madd x12, x10, x13, x11     // x12 = r * COLS + c
    ldrsw x19, [x9, x12, lsl #2]    // x19 = m[r][c]
```

That prints 7. Then it adds up each row: `10 26 42`. Notice that to compute an
address, you need to know `COLS` (the length of a row), but not `ROWS`. That is
why C lets you write `int m[][4]` but not `int m[3][]`.

Walking down a **column** means stepping a whole row at a time:
`COLS * 4` bytes. Exercise 12.6 does that.

## Binary search

On a **sorted** array you can find a value much faster: look at the middle;
if it is too small, the value can only be in the right half; repeat.
`examples/bsearch.s` reads the value to find from stdin:

```asm
search:
    cmp x10, x11
    b.gt missing                // while (lo <= hi), signed: hi can be -1
    add x12, x10, x11
    lsr x12, x12, #1            // x12 = mid = (lo + hi) / 2
    ldrsw x13, [x9, x12, lsl #2]    // x13 = a[mid]
    cmp x13, x22
    b.eq found
    b.lt go_right
    sub x11, x12, #1            // a[mid] > key: hi = mid - 1
    b search
go_right:
    add x10, x12, #1            // a[mid] < key: lo = mid + 1
    b search
```

```console
# echo 23 | ./bsearch
6
# echo 24 | ./bsearch
not found
```

`hi` starts at `N - 1` and can become -1, so the comparison is **signed**
(`b.gt`). A loop that looks at 12 elements one by one takes up to 12 steps;
binary search takes at most 4. For a million elements: 20.

## Sorting

`examples/bubble.s` and `examples/insertion.s` sort the same array two ways.
Read the C in each header first, then the assembly. Things to look for:

- **Bubble sort** compares neighbours `a[i]` and `a[i+1]`. It loads *both* with
  one `ldp w13, w14, [x12]` and, if they are out of order, stores them back
  swapped with one `stp w14, w13, [x12]`.
- **Insertion sort** moves `j` downwards and must stop at `j < 0`. Since `j`
  is a signed count, `tbnz x12, #63, place` tests its sign bit: "if `j` is
  negative, stop".

Step through the inner loop of each in the debugger with
`x/10dw &a` (10 decimal words at `a`) to watch the array change.

## C to assembly

| C | Assembly (`x9` = `a`, `x10` = `i`) |
|---|------------------------------------|
| `int a[] = {...};` | `a: .word ...` |
| `long a[] = {...};` | `a: .quad ...` |
| `sizeof a` | `. - a` (right after the array) |
| `sizeof a / sizeof a[0]` | `(. - a) / 4` |
| `x = a[i]` (int, as long) | `ldrsw x, [x9, x10, lsl #2]` |
| `x = a[i]` (long) | `ldr x, [x9, x10, lsl #3]` |
| `a[i] = x` (int) | `str w, [x9, x10, lsl #2]` |
| `p = a + i` | `add xp, x9, x10, lsl #2` |
| `x = *p++` (int) | `ldrsw x, [xp], #4` |
| `*--p = x` (int) | `str w, [xp, #-4]!` |
| `p - a` | `sub` then `lsr #2` (divide by element size) |
| `p < q` | `cmp xp, xq` / `b.lo` (unsigned) |
| `m[r][c]` | element `r * COLS + c`: `madd` then scaled load |

## Common mistakes

- **Wrong scale.** `lsl #2` on a `long` array reads the wrong elements, half
  of them misaligned halves of two numbers.
- **Adding 1 to a pointer** to move to the next `int`. Assembly pointers move
  in bytes: add 4.
- **`ldr w` for signed elements added to a 64-bit sum.** Negative values turn
  into large positives. Use `ldrsw`.
- **Off by one at the end.** `end` is one *past* the last element: stop when
  `p == end`, before reading.
- **Signed compares on pointers**, or unsigned compares on indices that can go
  negative (like `hi` in binary search, `j` in insertion sort).
- **Initialising `max` to 0.** Wrong for arrays of negative numbers.
- **Forgetting row length in 2D indexing.** `m[r][c]` is `r * COLS + c`, not
  `r + c`.

## Recap

- An array is consecutive elements; `a[i]` is at `a + i * size`.
- `[base, index, lsl #s]` scales the index by the element size (2^s).
- `(. - a) / size` lets the assembler count elements.
- `[p], #size` is `*p++`; `[p, #-size]!` is `*--p`.
- Assembly pointer arithmetic is in bytes; C's is in elements.
- `p - a` = byte distance / element size.
- Pointers compare unsigned.
- 2D arrays are row-major: `m[r][c]` is element `r * COLS + c`.
- Binary search halves the range each step on a sorted array.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md)
next.
