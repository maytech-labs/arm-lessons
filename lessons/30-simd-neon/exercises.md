# Lesson 30 exercises

Work in `lessons/30-simd-neon/work/` inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Use gdb's `p $v0` (or `p $v0.s`, `p $v0.b`) to look at vector registers while
you debug. Try each exercise before looking at the answers: programs are in
[solutions/](solutions/), written answers in
[solutions/README.md](solutions/README.md).

## Exercise 30.1 [warm-up]

1. How many lanes, of what size, in `v3.8h`? In `v3.2s`?
2. `v0` holds the bytes `00 01 02 ... 0f` (lowest first). What is `v0.s[1]`?
   What is `v0.h[7]`?
3. Which C element type matches `.4s` for integer data? For floating point?
4. After `addv s0, v1.4s`, where is the result? How do you get it into `w1`?
5. Why is there no `cmp` for vectors that sets the flags?
6. Which parts of `v8` must a function preserve?

## Exercise 30.2 [core]

Write `ex2.s` that computes the dot product of two 20-element `int` arrays
(`1..20` each) with `mla` and `addv`, plus a scalar tail loop (even if it does
not run for 20 elements).

Check: `dot = 2870`. Change the arrays to 21 elements: does your tail handle it?

## Exercise 30.3 [core]

Write `ex3.s` that counts the `'s'` characters in
`"she sells sea shells by the sea shore, surely"`, 16 bytes per step, using
`cmeq` and a reduction, with a byte tail.

Check: `'s' appears 9 times`.

## Exercise 30.4 [core]

Write `ex4.s` with `my_memcpy(dst, src, n)` that copies 16 bytes per
iteration with `ld1`/`st1` and the remaining bytes one at a time. Copy 100
bytes and check the result with libc's `memcmp`.

Check: `copied 100 bytes: ok`.

## Exercise 30.5 [stretch]

Write `ex5.s` that stores 16 RGB pixels as 48 interleaved bytes (all
`127, 63, 7`, except pixel 0, which is `135, 71, 15`), de-interleaves them with
`ld3`, and prints the sum of each channel. Why does the sum need `uaddlv`
rather than `addv`?

Check: `red 2040, green 1016, blue 120`.

## Exercise 30.6 [stretch]

Compile this C function with `gcc -O3 -S` and find the vector loop, the
reduction, and the tail in the output. Which instructions from this lesson do
you recognise? What does the compiler do differently from `sum_array.s`?

```c
long sum(const int *a, long n) {
    long s = 0;
    for (long i = 0; i < n; i++) s += a[i];
    return s;
}
```
