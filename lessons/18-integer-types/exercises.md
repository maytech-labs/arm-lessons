# Lesson 18 exercises

Work in `lessons/18-integer-types/work/` inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Print results with `printf` (`%d`, `%u`, `%ld`, `%lu`, `%lx`). Try each
exercise before looking at the answers: programs are in
[solutions/](solutions/), written answers in
[solutions/README.md](solutions/README.md).

## Exercise 18.1 [warm-up]

On Linux AArch64, what is:

1. `sizeof(int)`, `sizeof(long)`, `sizeof(long long)`, `sizeof(char *)`
2. the largest `unsigned short`
3. the smallest `int`
4. `(unsigned char)-1`
5. `(signed char)200`
6. `(int)0x1ffffffff`
7. `(long)(int)0xffffffff` and `(long)(unsigned)0xffffffff`
8. `-1 < 0u` and `-1L < 0u`

## Exercise 18.2 [warm-up]

Write the one instruction for each (`p` in `x1`, `i` an `int` in `w2`, `l` a
`long` in `x3`):

1. `long x = *(short *)p;`
2. `unsigned x = *(unsigned char *)p;`
3. `long x = i;`
4. `long x = (unsigned)i;`
5. `int x = (short)i;`
6. `long x = l + i;`
7. `long x = ((long *)p)[i];`

## Exercise 18.3 [core]

`(a + b) / 2` is wrong for large `unsigned` values: the sum wraps. Write
`ex3.s` that averages 4000000000 and 4000000002 both ways, using
`(a & b) + ((a ^ b) >> 1)` for the safe one. Why does that formula work?

Check: `naive 1852516353, safe 4000000001`.

## Exercise 18.4 [core]

Write `ex4.s` with `int sat_add(int a, int b)`: it returns `a + b`, or
`INT_MAX`/`INT_MIN` if the true sum is too big/too small. No branches: use
`adds`, `csel`, and the `vs` condition. Test `INT_MAX + 1`, `INT_MIN + -1`,
`10 + 20`, `INT_MIN + INT_MIN`.

Check: `2147483647 -2147483648 30 -2147483648`.

## Exercise 18.5 [core]

25! does not fit in 64 bits. Write `ex5.s` that computes it as a 128-bit value
in two registers, multiplying by 2, 3, ..., 25 in turn. Multiplying `hi:lo` by
a 64-bit `n`: the new `lo` is `mul lo, n`; the new `hi` is
`hi * n + umulh(lo, n)`. Print it with `%016lx%016lx`.

Check: `25! = 0x00000000000cd4a0619fb0907bc00000`.

## Exercise 18.6 [core]

Write `ex6.s` that sums the `signed char` array `{-1, -2, 100, -128, 27}`
twice: once loading with `ldrsb` and once with `ldrb`. Explain the wrong
answer exactly.

Check: `with ldrsb: -4, with ldrb: 764`.

## Exercise 18.7 [stretch]

Write `ex7.s` with a function that prints whether `a * b` overflows 64 unsigned
bits, using `umulh`. Test `2^32 * (2^32 - 1)` and `2^32 * 2^32`.

Check:

```
4294967296 * 4294967295: fits
4294967296 * 4294967296: overflow
```

## Exercise 18.8 [stretch]

Write `ex8.s` that prints `(bool)x` and `(unsigned char)x` for `x` = 0, 1,
256, -1.

Check:

```
x = 0: bool 0, unsigned char 0
x = 1: bool 1, unsigned char 1
x = 256: bool 1, unsigned char 0
x = -1: bool 1, unsigned char 255
```
