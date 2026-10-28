# Lesson 23 exercises: Floating point

Work in `lessons/23-floating-point/linux/work/` (on macOS: `apple-silicon/work/`) (it is git-ignored). Copy the Makefile
from `examples/` into it, so `make ex3` builds `ex3.s`. If your program calls
`sqrt` or another `<math.h>` function, add an explicit rule with `-lm`, as in
`examples/Makefile`.

Try each exercise before you look at the answer. Programs are in
[linux/solutions/](linux/solutions/) as `exN.s`; written answers are in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 23.1 [warm-up]

Work by hand, on paper. No programs.

1. Write the 64-bit pattern (in hex) of the double `5.0`.
2. Write the 64-bit pattern of the double `-0.75`.
3. The 32 bits `0x40490000` are a `float`. What number is it?
4. Which of these can be loaded with `fmov d0, #value`?
   `0.5`, `3.0`, `0.1`, `31.0`, `32.0`, `100.0`, `-0.25`, `0.1875`, `0.0625`, `0.0`.

Check parts 1 and 2 by changing `fp_bits.s` to print your values.

## Exercise 23.2 [warm-up]

Predict the value in the named register after each snippet. Assume each starts
fresh. Then check a few in the debugger (`p $d0` in gdb, `p $d0` or
`register read d0` in lldb).

```asm
// (a) x0 = ?
    fmov d0, #-3.75
    fcvtzs x0, d0

// (b) x0 = ?
    fmov d0, #-3.75
    fcvtzu x0, d0

// (c) x0 = ?
    mov x0, #10
    scvtf d0, x0
    fmov d1, #4.0
    fdiv d0, d0, d1
    fcvtzs x0, d0

// (d) d0 = NaN, d1 = 1.0. Which of these branches are taken?
    fcmp d0, d1
    b.ge  L1
    b.lt  L2
    b.ne  L3
    b.mi  L4

// (e) x1 = ? and x2 = ?
    fmov d0, #1.0
    fmov x1, d0
    fcvtzs x2, d0
```

## Exercise 23.3 [warm-up]

File: `ex3.s`. Print a Fahrenheit to Celsius table for 0, 20, 40, 60, 80, 100
degrees Fahrenheit, using `c = (f - 32) * 5 / 9` in `double`. Keep `f` as a
`long` loop counter and convert it with `scvtf`. Use the format
`"%3ld F = %6.1f C\n"`.

Hint: `32.0` is not an `fmov` immediate.

Expected output:

```console
$ ./ex3
  0 F =  -17.8 C
 20 F =   -6.7 C
 40 F =    4.4 C
 60 F =   15.6 C
 80 F =   26.7 C
100 F =   37.8 C
```

## Exercise 23.4 [core]

File: `ex4.s`. Write `double poly(double x)` that returns `3x^2 - 2x + 1`
using Horner's rule, `(3x - 2) * x + 1`, with two `fmadd` instructions and no
`fmul`. In `main`, loop over the array `{-1.0, 0.0, 1.0, 2.5}` stored in
`.rodata` and print each result with `"p(%.1f) = %f\n"`.

Expected output:

```console
$ ./ex4
p(-1.0) = 6.000000
p(0.0) = 1.000000
p(1.0) = 2.000000
p(2.5) = 14.750000
```

## Exercise 23.5 [core]

File: `ex5.s`. Write `void solve(double a, double b, double c)` that prints the
real roots of `a x^2 + b x + c = 0`. First print the equation with
`"%g x^2 + %g x + %g: "`. Then compute the discriminant `b*b - 4*a*c`
(try `fmsub`) and:

- if it is negative, print `"no real roots\n"`;
- if it is zero, print `"one root %f\n"` with `-b / 2a`;
- otherwise print `"two roots %f and %f\n"` with `(-b + s) / 2a` and
  `(-b - s) / 2a`, where `s` is the square root of the discriminant.

Call it for `(1, -3, 2)`, `(1, 2, 1)` and `(1, 2, 5)`. Hint: `solve` calls
`printf` and then still needs `a`, `b`, `c`. Where must they live?

Expected output:

```console
$ ./ex5
1 x^2 + -3 x + 2: two roots 2.000000 and 1.000000
1 x^2 + 2 x + 1: one root -1.000000
1 x^2 + 2 x + 5: no real roots
```

## Exercise 23.6 [core]

File: `ex6.s`. Write:

- `double dot(const double *a, const double *b, long n)`, the sum of `a[i] * b[i]`;
- `double length(const double *v, long n)`, which returns `sqrt(dot(v, v, n))`
  using the C library's `sqrt` (not `fsqrt`, for practice).

Print the results for `a = {1, 2, 3}` and `b = {4, 5, 6}`. Add the `-lm` rule
to your Makefile.

Expected output:

```console
$ ./ex6
dot(a, b) = 32.000000
|a| = 3.741657
|b| = 8.774964
```

## Exercise 23.7 [core]

File: `ex7.s`. Add `0.1` to a sum ten times, once in `float` (`s` registers)
and once in `double`. Print both sums with `"%.17f"` (remember to widen the
float). Then print whether the double sum `== 1.0`, and whether
`fabs(sum - 1.0) < 1e-9`, each as `0` or `1` using `cset`.

Expected output:

```console
$ ./ex7
float  sum = 1.00000011920928955
double sum = 0.99999999999999989
double sum == 1.0: 0
fabs(double sum - 1.0) < 1e-9: 1
```

Before you run it: which of the two sums do you expect to be closer to 1.0?

## Exercise 23.8 [stretch]

File: `ex8.s`. Write `double my_atof(const char *s)` (the floating-point
version of lesson 17's `atoi`). Accept an optional `+` or `-`, digits, and
optionally a `.` followed by more digits. A simple method: build all the digits
into `value` with `value = value * 10 + digit` (one `fmadd`), multiply a
`scale` by 10 for every digit after the point, and return `sign * value / scale`.

Test it on `"3.25"`, `"-0.5"`, `"42"`, `"+7.75"`, `"12.125"`, printing
`"\"%s\" -> %f\n"`.

Expected output:

```console
$ ./ex8
"3.25" -> 3.250000
"-0.5" -> -0.500000
"42" -> 42.000000
"+7.75" -> 7.750000
"12.125" -> 12.125000
```

## Exercise 23.9 [stretch]

File: `ex9.s`. Estimate pi by integrating `4 / (1 + x^2)` from 0 to 1 with the
midpoint rule:

```c
double integrate_pi(long n) {
    double h = 1.0 / n, sum = 0;
    for (long i = 0; i < n; i++) {
        double x = (i + 0.5) * h;
        sum += 4 / (1 + x * x);
    }
    return sum * h;
}
```

Call it with `n = 1000`, print the estimate with `"pi ~ %.10f with n = %ld\n"`,
then print the error against `3.141592653589793` with `"error = %.2e\n"`.

Expected output:

```console
$ ./ex9
pi ~ 3.1415927369 with n = 1000
error = 8.33e-08
```

Try `n = 10` and `n = 100000`. How does the error change when `n` grows ten
times?
