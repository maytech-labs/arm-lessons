# Lesson 23: Floating point

So far every number you have touched was an integer. C also has `float` and
`double`, numbers with a fractional part like `3.75` or `0.1`. The CPU handles
them with a separate set of registers and a separate set of instructions. This
lesson teaches both, shows exactly how a `double` is stored in its 64 bits, and
ends with two small numeric programs.

## Goals

After this lesson you can:

- Name the floating-point registers `v0`-`v31` and their `d` (double) and `s`
  (float) views.
- Decode a `double` or `float` into sign, exponent and fraction, and print its bits.
- Get a floating-point constant into a register, with `fmov` or from memory.
- Use `fadd`, `fsub`, `fmul`, `fdiv`, `fsqrt`, `fabs`, `fneg`, `fmadd`, `fmsub`.
- Compare with `fcmp` and pick the right condition, including when a value is NaN.
- Convert between integers, `float` and `double` the way C casts do.
- Pass doubles to and from functions, keep them across calls in `d8`-`d15`,
  and print them with `printf`.
- Call `sqrt` and `pow` from the C math library, and link it with `-lm`.

## Before you start

You need:

- [Lesson 12](../12-arrays-and-pointers/) for walking arrays.
- [Lesson 15](../15-calling-convention/) for argument registers and who saves what.
- [Lesson 16](../16-calling-c/) for calling `printf`.
- [Lesson 18](../18-integer-types/) for casts between integer types; this lesson
  adds casts to and from floating point.

## A second set of registers

The integer registers `x0`-`x30` cannot do floating-point arithmetic. For that
the CPU has 32 more registers, `v0` to `v31`. Each one is 128 bits wide, and you
name the part you want with a letter, just as `w0` names the low half of `x0`:

| Name | Size | C type | Used in this lesson |
|------|------|--------|---------------------|
| `q0` | 128 bits | (none; `long double` on Linux, not covered) | no |
| `d0` | 64 bits | `double` | yes, most of the time |
| `s0` | 32 bits | `float` | yes |
| `h0` | 16 bits | `_Float16` | no |

`d0` is the low 64 bits of `v0`, and `s0` is the low 32 bits. Writing `d0` or
`s0` zeroes the rest of `v0`, the same way writing `w0` zeroes the top of `x0`.

The `v` name exists because these registers are also used for SIMD (doing
several operations at once), which this course does not cover. From here on you
will only write `d` and `s` names.

The instructions are new too. Almost all of them start with `f`: `fadd`,
`fmul`, `fcmp`, `fmov`. An instruction works on doubles if its registers are `d`
registers, and on floats if they are `s` registers:

```asm
    fadd d0, d1, d2     // double: d0 = d1 + d2
    fadd s0, s1, s2     // float:  s0 = s1 + s2
```

You cannot mix sizes in one instruction (`fadd d0, s1, d2` is an error), and you
cannot use `x` registers with `fadd`. To combine an integer with a double you
convert first, later in this lesson.

## Your first floating-point program

In C:

```c
#include <stdio.h>

int main(void) {
    double a = 1.5;
    double b = 2.25;
    double c = a + b;
    printf("%f + %f = %f\n", a, b, c);
    return 0;
}
```

In assembly (`examples/fp_add.s`):

```asm
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    fmov d0, #1.5               // double a = 1.5;
    fmov d1, #2.25              // double b = 2.25;
    fadd d2, d0, d1             // double c = a + b;

    adrp x0, fmt                // printf(fmt, a, b, c):
    add x0, x0, :lo12:fmt       //   format in x0, the doubles in d0, d1, d2
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
fmt:
    .asciz "%f + %f = %f\n"
```

Three new things:

- `fmov d0, #1.5` puts the constant 1.5 into `d0`. Only some constants fit
  in the instruction; you will see the rule shortly.
- `fadd d2, d0, d1` adds two doubles.
- `printf` gets its doubles in `d0`, `d1`, `d2`. The format string, a pointer,
  is still in `x0`.

That last point is the AAPCS64 rule: **integer and pointer arguments go in
`x0`-`x7`, floating-point arguments go in `d0`-`d7`, and the two are counted
separately.** The first double is in `d0` no matter how many integer arguments
come before it.

If you have seen x86-64 assembly, you may remember that `printf` there needs the
number of vector registers in `al`. AArch64 has no such rule. Just put the
values in place and call.

Predict the output, then check:

```console
$ cd examples
$ make
$ ./fp_add
1.500000 + 2.250000 = 3.750000
```

`%f` prints six digits after the point by default. `%.2f` would print two,
`%.17f` seventeen.

## How a double is stored

A `double` is 64 bits, split into three fields (this layout is the IEEE 754
standard, used by every modern CPU):

```
 63  62        52 51                                                0
+---+------------+---------------------------------------------------+
| s |  exponent  |                     fraction                      |
+---+------------+---------------------------------------------------+
 1 bit  11 bits                         52 bits
```

The value is:

```
value = (-1)^s  x  1.fraction (in binary)  x  2^(exponent - 1023)
```

The `1023` is called the *bias*: it lets the 11-bit exponent field (0 to 2047)
stand for powers from about -1022 to +1023. The leading `1.` is not stored; every
normal number starts with it, so storing it would waste a bit.

Work through `1.0` by hand:

- It is positive: `s = 0`.
- `1.0 = 1.0 x 2^0`, so the exponent field is `0 + 1023 = 1023 = 0x3ff`.
- The fraction after `1.` is all zeros.
- Bits: `0 | 01111111111 | 000...0` = `0x3ff0000000000000`.

Now `-2.5`:

- Negative: `s = 1`.
- `2.5 = 10.1` in binary `= 1.01 x 2^1`, so the exponent field is `1 + 1023 = 1024 = 0x400`.
- The fraction is `01000...0`: the first fraction bit (bit 51) is 0, the second
  (bit 50) is 1, which is `0x4000000000000` as a 52-bit number.
- Bits: `1 | 10000000000 | 0100...0` = `0xc004000000000000`.

And `0.1`? In binary it is `0.000110011001100110011...`, repeating forever. 52
bits cannot hold it, so the CPU stores the nearest value it can. **0.1 is not
exactly representable.** This is the root of most floating-point surprises.

A `float` has the same shape, just smaller: 1 sign bit, 8 exponent bits with
bias 127, and 23 fraction bits. `1.0f` is `0x3f800000`.

A few bit patterns are special:

| Exponent field | Fraction | Meaning |
|----------------|----------|---------|
| all zeros | zero | `+0.0` or `-0.0` (yes, two zeros) |
| all zeros | non-zero | a tiny "subnormal" number |
| all ones | zero | `+infinity` or `-infinity` (e.g. `1.0 / 0.0`) |
| all ones | non-zero | NaN, "not a number" (e.g. `0.0 / 0.0`) |

Floating-point division by zero does not crash, unlike what you might fear. It
produces infinity or NaN and the program carries on.

### Seeing the bits

`examples/fp_bits.s` prints the bits of a few values. The key instruction is:

```asm
    fmov x1, d0                 // x1 = the raw bits of d (no conversion)
```

`fmov` between an `x` register and a `d` register copies the 64 bits unchanged.
It does **not** turn 1.0 into 1; it gives you `0x3ff0000000000000`. Then
`ubfx` (lesson 8) pulls out the fields:

```asm
    ubfx x2, x1, #63, #1        // sign:      bit 63
    ubfx x3, x1, #52, #11       // exponent:  bits 52-62
    ubfx x4, x1, #0, #52        // fraction:  bits 0-51
```

and one `printf` call shows them all. Notice the arguments: the double is in
`d0`, the four integers in `x1`-`x4`. Two separate counts again.

For a float, `fmov w1, s0` copies the 32 bits, and `fcvt d0, s0` widens the
float to a double so `printf` can print it (more on `fcvt` later).

Before running it, write down what you expect for `0.0` and `-0.0`. Then:

```console
$ ./fp_bits
  1.000000  bits 0x3ff0000000000000  sign 0  exp 1023  frac 0x0000000000000
 -2.500000  bits 0xc004000000000000  sign 1  exp 1024  frac 0x4000000000000
  0.100000  bits 0x3fb999999999999a  sign 0  exp 1019  frac 0x999999999999a
  0.000000  bits 0x0000000000000000  sign 0  exp    0  frac 0x0000000000000
 -0.000000  bits 0x8000000000000000  sign 1  exp    0  frac 0x0000000000000
float 1.000000  bits 0x3f800000
float 0.100000  bits 0x3dcccccd
```

Look at `0.1`: the fraction is `999...9a`, a repeating pattern rounded up at the
end. `-0.0` differs from `0.0` only in the sign bit.

## Getting constants into registers

There are three ways.

**1. `fmov` with an immediate.** Only numbers that fit in 8 bits of encoding are
allowed: values of the form `±(n / 16) x 2^e` where `n` is 16 to 31 and `e` is -3
to 4. In practice: simple values between 0.125 and 31 with few binary digits.

| Fits in `fmov #imm` | Does not fit |
|---------------------|--------------|
| `0.125`, `0.25`, `0.5`, `1.0`, `1.5`, `2.0`, `2.25`, `3.0`, `10.0`, `31.0`, and their negatives | `0.0`, `0.1`, `3.14159`, `32.0`, `100.0`, `1e-12` |

If it does not fit, the assembler stops with an error such as
`expected compatible register or floating-point constant`.

**2. Zero from `xzr`.** `fmov d0, xzr` copies 64 zero bits, which is `0.0`.
(For a float: `fmov s0, wzr`.)

**3. From memory.** Put the constant in `.rodata` with `.double` (8 bytes) or
`.float` (4 bytes), and load it with `ldr` into a `d` or `s` register:

```asm
    adrp x0, pi
    ldr d0, [x0, :lo12:pi]      // d0 = 3.141592653589793

    .section .rodata
    .p2align 3                  // doubles want 8-byte alignment
pi:
    .double 3.141592653589793
```

`ldr d0` loads 8 bytes into the FP register; `ldr s0` loads 4; `str d0` and
`str s0` store. All the addressing modes from lesson 11 work, including
`[x0, x1, lsl #3]` for indexing an array of doubles and post-index `[x0], #8`.

This is what C compilers do for every constant that does not fit `fmov`.

## Arithmetic

| C | Assembly (double) | Notes |
|---|-------------------|-------|
| `a + b` | `fadd d0, d1, d2` | |
| `a - b` | `fsub d0, d1, d2` | |
| `a * b` | `fmul d0, d1, d2` | |
| `a / b` | `fdiv d0, d1, d2` | no trap on divide by zero |
| `sqrt(a)` | `fsqrt d0, d1` | a single instruction |
| `fabs(a)` | `fabs d0, d1` | clears the sign bit |
| `-a` | `fneg d0, d1` | flips the sign bit |
| `c + a * b` | `fmadd d0, d1, d2, d3` | `d0 = d3 + d1 * d2`, rounded once |
| `c - a * b` | `fmsub d0, d1, d2, d3` | `d0 = d3 - d1 * d2` |
| `a = b` | `fmov d0, d1` | copy between FP registers |

There is no `fadd d0, d1, #2.0`: arithmetic takes registers only. Put the
constant in a register first.

`fmadd` is the floating-point cousin of `madd` from lesson 7. It is faster and
slightly more accurate than `fmul` then `fadd`, because it rounds only once.

`examples/fp_ops.s` tries every row of the table with `a = 7.5` and `b = -2.0`.
It keeps `a` and `b` in `d8` and `d9`, because those survive calls to `printf`
(the rules are below). Predict each line before you run it:

```console
$ ./fp_ops
a            = 7.500000
b            = -2.000000
a + b        = 5.500000
a - b        = 9.500000
a * b        = -15.000000
a / b        = -3.750000
sqrt(a)      = 2.738613
fabs(b)      = 2.000000
-a           = -7.500000
a * b + 10   = -5.000000
pi * r * r   = 12.566371
```

Its helper `show(const char *name, double value)` is worth reading: `name`
arrives in `x0` and `value` in `d0`. To call `printf(fmt, name, value)` it moves
`name` to `x1`, puts `fmt` in `x0`, and leaves `value` in `d0` untouched.

## Comparing

In C:

```c
if (a < b) ... else if (a > b) ... else ...
```

`fcmp d0, d1` compares two doubles and sets the same `N Z C V` flags you know
from `cmp`. You can also compare with zero directly: `fcmp d0, #0.0` (zero is the
only immediate allowed here).

There are four possible outcomes, not three. The fourth is **unordered**: at
least one of the values is NaN, and NaN is not less than, equal to, or greater
than anything, not even itself.

| Outcome | N Z C V |
|---------|---------|
| less    | 1 0 0 0 |
| equal   | 0 1 1 0 |
| greater | 0 0 1 0 |
| unordered | 0 0 1 1 |

So the conditions you know mean slightly different things after `fcmp`. Use
this table and you will match C exactly:

| C | Branch / `cset` condition | True when unordered? |
|---|---------------------------|----------------------|
| `a == b` | `eq` | no |
| `a != b` | `ne` | yes (C agrees: `NaN != x` is true) |
| `a < b`  | **`mi`** | no |
| `a <= b` | **`ls`** | no |
| `a > b`  | `gt` | no |
| `a >= b` | `ge` | no |
| `isnan(a) \|\| isnan(b)` | `vs` | yes |

The trap is `lt` and `le`. They test `N != V`, and unordered has `N = 0, V = 1`,
so **`lt` and `le` are true when a NaN is involved.** `a < b` with `b.lt` would
claim that NaN is less than 1. Use `mi` and `ls`.

`examples/fp_compare.s` has a `compare(a, b)` function that branches four ways:

```asm
    fcmp d0, d1                 // sets NZCV; d0 and d1 are unchanged
    b.vs compare_unordered      // V=1: at least one is NaN
    b.mi compare_less           // a < b
    b.gt compare_greater        // a > b
    // only "equal" is left
```

It makes a NaN with `0.0 / 0.0` and then shows the trap with `cset`. Before
running: what will `NaN == NaN` print?

```console
$ ./fp_compare
 1.0 vs  2.0: less
 2.0 vs  1.0: greater
 2.0 vs  2.0: equal
 nan vs  1.0: unordered
 nan vs  nan: unordered
NaN < 1.0 using lt: 1, using mi: 0
NaN == NaN: 0
```

`NaN == NaN` is false. That is why the C idiom `x != x` tests for NaN.

To pick between two doubles without a branch there is `fcsel`, the FP version
of `csel`: `fcsel d0, d1, d2, mi` sets `d0 = (condition) ? d1 : d2`.

## Conversions: C casts

C converts between integers and floating point all the time, sometimes silently.
Each conversion is one instruction:

| C | Assembly | Rule |
|---|----------|------|
| `(double)n` with `long n` | `scvtf d0, x0` | signed integer to double |
| `(double)u` with `unsigned long u` | `ucvtf d0, x0` | unsigned integer to double |
| `(double)i` with `int i` | `scvtf d0, w0` | use the `w` register for 32-bit ints |
| `(long)d` | `fcvtzs x0, d0` | toward zero, signed |
| `(unsigned long)d` | `fcvtzu x0, d0` | toward zero, unsigned |
| `(int)d` | `fcvtzs w0, d0` | |
| `(double)f` with `float f` | `fcvt d0, s0` | always exact |
| `(float)d` | `fcvt s0, d0` | rounds to the nearest float |

The names: `scvtf` is "signed convert to float", `fcvtzs` is "float convert,
round toward **z**ero, **s**igned". Rounding toward zero is exactly what a C
cast does: `(long)2.7` is 2 and `(long)-2.7` is -2, not -3.

Compare these two, they are easy to mix up:

```asm
    fmov   x1, d0       // x1 = the bits of d0:   1.0 -> 0x3ff0000000000000
    fcvtzs x1, d0       // x1 = d0 as an integer: 1.0 -> 1
```

C also converts silently. In `n * 2.5` with `long n`, the "usual arithmetic
conversions" turn `n` into a double first, so you write `scvtf` then `fmul`. When
you pass a `float` to a variadic function like `printf`, C promotes it to
`double`: you must `fcvt d0, s0` before the call, because `%f` always reads a
double.

What happens when the double does not fit? `(long)1e20` is undefined behaviour
in C. On AArch64, `fcvtzs` saturates: it gives the largest `long`. A negative
value converted with `fcvtzu` gives 0. NaN converts to 0. Do not rely on this in
C code, but now you know what the hardware does.

`examples/fp_convert.s` runs every row. Predict each line, especially the last
two:

```console
$ ./fp_convert
(double)7 / 2         = 3.500000
7 / 2 with integers   = 3
(long)2.7             = 2
(long)-2.7            = -2
(unsigned long)-2.7   = 0
(long)1e20            = 9223372036854775807
(double)(long)-1      = -1.000000
(double)(ulong)-1     = 18446744073709551616.000000
0.1 as a double       = 0.10000000000000001
0.1 as a float        = 0.10000000149011612
```

The same 64 bits of `-1` give `-1.0` through `scvtf` and about 1.8e19 through
`ucvtf`: signedness matters here just as in lesson 18. And the last two lines
show that 0.1 is stored inexactly in both types, with the float hundreds of
millions of times further off.

Other rounding modes exist when you need them: `fcvtms` rounds down (like
`floor`), `fcvtps` rounds up (like `ceil`), `fcvtas` rounds to nearest with ties
away from zero (like `lround`). You will rarely need them; a cast is `fcvtzs`.

## Functions with floating-point arguments

The calling convention (lesson 15) extends naturally:

- The first eight floating-point arguments go in `d0`-`d7` (`s0`-`s7` for
  floats), counted separately from integer arguments in `x0`-`x7`.
- A `double` result comes back in `d0` (`float` in `s0`).
- `d8`-`d15` are **callee-saved**: a function that uses them must save and
  restore them. Only the low 64 bits are preserved (the `d` part), which is all
  you use.
- All other FP registers (`d0`-`d7`, `d16`-`d31`) are **caller-saved**: any call
  may destroy them.

So `double scale(long n, double x)` receives `n` in `x0` and `x` in `d0`. In C:

```c
double average3(double a, double b, double c) { return (a + b + c) / 3.0; }
double scale(long n, double x) { return n * x; }
double sum_squares(const double *a, long n) {
    double sum = 0.0;
    while (n != 0) { double v = *a++; sum = sum + v * v; n--; }
    return sum;
}
```

In assembly (`examples/fp_args.s`):

```asm
average3:
    fadd d0, d0, d1             // a + b
    fadd d0, d0, d2             // + c
    fmov d1, #3.0
    fdiv d0, d0, d1             // / 3.0
    ret

scale:
    scvtf d1, x0                // (double)n
    fmul d0, d1, d0             // n * x, returned in d0
    ret

sum_squares:
    fmov d0, xzr                // double sum = 0.0;
sum_squares_loop:
    cbz x1, sum_squares_done    // while (n != 0)
    ldr d1, [x0], #8            //   double v = *a++;
    fmadd d0, d1, d1, d0        //   sum = sum + v * v;
    sub x1, x1, #1              //   n--;
    b sum_squares_loop
sum_squares_done:
    ret
```

`sum_squares` takes a pointer (`x0`), a count (`x1`), and returns a double
(`d0`): each lives in its own kind of register.

`main` computes `average3(1, 2, 4.5) + scale(3, 1.25)`. The result of
`average3` must survive the call to `scale`, so `main` copies it into `d8`, and
saves the caller's `d8` in its prologue:

```asm
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]           // we keep a double in d8 across calls
    ...
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
```

`stp d8, d9, [sp, #16]` saves two at once, as in `fp_ops.s`.

```console
$ ./fp_args
average3(1, 2, 4.5) = 2.500000
scale(3, 1.250000) = 3.750000
sum_squares({1.5, 2, 3}, 3) = 15.250000
total = 6.250000
```

The second line passes `printf(fmt, 3, 1.25, s)`: `3` in `x1`, `1.25` in `d0`,
`s` in `d1`. The format string decides the order in which `printf` reads them,
and it reads each `%ld` from the next `x` register and each `%f` from the next
`d` register.

## The math library

`sqrt`, `pow`, `floor`, `sin`, `exp` and friends live in the C math library,
declared in `<math.h>`. You call them like any function: arguments in `d0`,
`d1`, result in `d0`.

```c
printf("%f\n", sqrt(2.0));
printf("%f\n", pow(2.0, 10.0));
printf("%f\n", floor(-2.5));
```

```asm
    fmov d0, #2.0
    bl sqrt                     // result in d0
    ...
    fmov d0, #2.0               // pow(2.0, 10.0)
    fmov d1, #10.0
    bl pow
```

On Linux the math library is a separate file, `libm`, and the linker does not
search it unless you ask with `-lm`. Without it you get:

```console
$ gcc math_lib.s -o math_lib
/usr/bin/ld: ... undefined reference to `sqrt'
```

The shared Makefile rule does not add `-lm`, so `examples/Makefile` adds an
explicit rule for this one program:

```make
include ../../../../mk/linux.mk

# sqrt, pow and floor live in the math library: link it with -lm.
math_lib: math_lib.s
	$(CC) $(ASFLAGS) -o $@ $< -lm
```

An explicit rule for a target wins over the general `%: %.s` pattern rule.
`-lm` goes after the source file: the linker searches libraries for names that
are still missing at that point.

```console
$ make math_lib
$ ./math_lib
sqrt(2)      = 1.414214
pow(2, 10)   = 1024.000000
pow(2, 0.5)  = 1.414214
floor(-2.5)  = -3.000000
```

For square roots you do not need the library at all: `fsqrt` is one
instruction, and `gcc` turns `sqrt(x)` into `fsqrt` when optimising.

## A numeric program: Newton's method

Newton's method finds `sqrt(a)` by guessing `x` and repeatedly improving it:

```
next = (x + a / x) / 2
```

Stop when the guess stops changing (the difference is below `1e-12`). In C:

```c
double newton_sqrt(double a) {
    double x = a, diff;
    long step = 0;
    do {
        double next = (x + a / x) * 0.5;
        diff = fabs(next - x);
        x = next;
        printf("step %ld: x = %.12f\n", ++step, x);
    } while (diff >= 1e-12 && step < 50);
    return x;
}
```

`examples/newton.s` is a direct translation. Every value that must survive the
`printf` inside the loop lives in a callee-saved register: `a` in `d8`, `x` in
`d9`, the tolerance in `d10`, `diff` in `d11`, `step` in `x19`. The loop test
uses `mi` for "less than":

```asm
    fcmp d11, d10               // diff < tolerance ?
    b.mi newton_done            //   yes: stop
```

Count how many steps you think it needs for `a = 2`, then run it:

```console
$ ./newton
step 1: x = 1.500000000000
step 2: x = 1.416666666667
step 3: x = 1.414215686275
step 4: x = 1.414213562375
step 5: x = 1.414213562373
step 6: x = 1.414213562373
newton: 1.414213562373
fsqrt:  1.414213562373
```

The number of correct digits roughly doubles each step. That is why Newton's
method is famous.

## Another: mean and standard deviation

`examples/stats.s` computes the mean and the (population) standard deviation of
an array of eight doubles:

```c
double mean(const double *a, long n) {
    double sum = 0;
    for (long i = 0; i < n; i++) sum += a[i];
    return sum / n;                             // n is converted to double
}

double stddev(const double *a, long n) {
    double m = mean(a, n), sum = 0;
    for (long i = 0; i < n; i++) { double d = a[i] - m; sum += d * d; }
    return sqrt(sum / n);
}
```

Things to notice in the assembly:

- `ldr d1, [x0, x2, lsl #3]` indexes an array of doubles: 8-byte elements, so
  shift the index by 3, exactly as for an array of `long`.
- `return sum / n` hides a conversion: `scvtf d1, x1` then `fdiv`.
- `stddev` calls `mean`, so it keeps `a` and `n` in `x19`, `x20`. The mean comes
  back in `d0` and is used immediately, with no further calls, so a scratch
  register (`d2`) is fine for it.
- `fsqrt` is used instead of `sqrt()`, so no `-lm` is needed.

```console
$ ./stats
n      = 8
mean   = 5.000000
stddev = 2.000000
```

## Compare with the compiler

Write a small C function and look at what `gcc` makes of it:

```c
double avg(double a, double b) { return (a + b) / 2; }
int less(double a, double b) { return a < b; }
```

```console
$ gcc -O2 -S avg.c -o -
avg:
	fadd	d0, d0, d1
	fmov	d2, 5.0e-1
	fmul	d0, d0, d2
	ret
less:
	fcmpe	d0, d1
	cset	w0, mi
	ret
```

Two things to notice. The compiler replaced `/ 2` with `* 0.5`, which is exact
and faster. And for `a < b` it used `mi`, just as the table above says. (`fcmpe`
is `fcmp` that also raises an "invalid" exception flag for NaN; the result in
the flags is the same.) `gcc` writes the immediate without `#`
(`fmov d2, 5.0e-1`); GNU `as` accepts either form.

## C to assembly

| C | Assembly |
|---|----------|
| `double d = 1.5;` | `fmov d0, #1.5` |
| `double d = 0.0;` | `fmov d0, xzr` |
| `double d = 3.14159;` | `.double 3.14159` in `.rodata`, then `adrp` + `ldr d0, [x0, :lo12:k]` |
| `float f = 0.1f;` | `.float 0.1`, then `ldr s0, ...` |
| `a + b`, `a - b`, `a * b`, `a / b` | `fadd`, `fsub`, `fmul`, `fdiv` |
| `sqrt(a)`, `fabs(a)`, `-a` | `fsqrt`, `fabs`, `fneg` |
| `c + a * b` | `fmadd d0, da, db, dc` |
| `p[i]` with `double *p` | `ldr d0, [x0, x1, lsl #3]` |
| `if (a < b)` | `fcmp da, db` + `b.mi` |
| `if (a <= b)` | `fcmp da, db` + `b.ls` |
| `if (a > b)`, `>=`, `==`, `!=` | `b.gt`, `b.ge`, `b.eq`, `b.ne` |
| `if (x == 0.0)` | `fcmp d0, #0.0` + `b.eq` |
| `isnan(x)` | `fcmp d0, d0` + `b.vs` |
| `(double)n`, `(double)u` | `scvtf d0, x0`, `ucvtf d0, x0` |
| `(long)d`, `(unsigned long)d` | `fcvtzs x0, d0`, `fcvtzu x0, d0` |
| `(double)f`, `(float)d` | `fcvt d0, s0`, `fcvt s0, d0` |
| reinterpret bits (`memcpy(&u, &d, 8)`) | `fmov x0, d0` / `fmov d0, x0` |
| `double f(long n, double x)` | `n` in `x0`, `x` in `d0`, result in `d0` |
| local double kept across a call | `d8`-`d15`, saved in the prologue |
| `printf("%f", d)` | format in `x0`, `d` in `d0` |
| `printf("%f", f)` with `float f` | `fcvt d0, s0` first |
| `sqrt`, `pow` from `<math.h>` | `bl sqrt`, `bl pow`; link with `-lm` |

## Common mistakes

- **`fmov` with a constant that does not fit.** `fmov d0, #0.1` or
  `fmov d0, #100.0` fails to assemble with "expected compatible register or
  floating-point constant". Put the value in `.rodata` with `.double` and load
  it with `ldr d0`.
- **Expecting a double in `d0`-`d7` to survive a call.** They are caller-saved.
  A first draft of `fp_bits.s` made `-0.0` with `fneg d0, d0` right after a
  `show_double` call, assuming `d0` still held `0.0`. `printf` had changed it,
  and the program printed the bits of some random number. Keep values in
  `d8`-`d15` (and save them), or recompute them after the call.
- **Using `lt` or `le` after `fcmp`.** They are true when either value is NaN.
  Use `mi` for `<` and `ls` for `<=`.
- **Comparing doubles with `==` after arithmetic.** `0.1` added ten times is not
  `1.0` (exercise 23.7). Compare `fabs(a - b)` with a small tolerance instead.
- **Confusing `fmov x0, d0` with `fcvtzs x0, d0`.** The first copies bits
  (`1.0` becomes `0x3ff0000000000000`), the second converts (`1.0` becomes `1`).
  If you see a huge integer where you expected a small one, you used `fmov`.
- **Passing a float to `printf` without widening it.** `%f` reads a whole double
  from `d0`. A float in `s0` only fills the low 32 bits, so `printf` sees a
  tiny or meaningless double and prints `0.000000` or nonsense. `fcvt d0, s0` first.
- **Putting the double in `x1` for `printf`.** `printf("%f", d)` wants `d` in
  `d0`, not in `x1`. Integers and doubles are numbered separately.
- **Loading a double with an integer load.** `ldr x0, [x1]` loads the 8 bytes into
  an integer register; `fadd` cannot use it. Use `ldr d0, [x1]`.
- **Forgetting `-lm` on Linux.** The link fails with
  "undefined reference to `sqrt'" (or `pow`, `sin`...). Add an explicit Makefile
  rule with `-lm` after the source file.
- **Expecting a cast to round.** `(long)2.9` is 2. `fcvtzs` truncates toward
  zero. To round to nearest, use `lround()` from the math library or `fcvtas`.

## Recap

- FP values live in `v0`-`v31`: `d` names a `double`, `s` a `float`. Writing one
  zeroes the rest of the register.
- A double is sign (1 bit), exponent (11 bits, bias 1023) and fraction (52
  bits); a float is 1, 8 (bias 127) and 23. Many decimals, like 0.1, are
  stored only approximately.
- Constants: `fmov #imm` for a few simple values, `fmov d0, xzr` for zero,
  otherwise `.double`/`.float` in `.rodata` and `ldr d0`/`ldr s0`.
- Arithmetic is `fadd fsub fmul fdiv fsqrt fabs fneg fmadd fmsub`, registers only.
- `fcmp` has four outcomes. Use `mi`/`ls` for `<`/`<=`, `gt`/`ge`/`eq`/`ne`
  for the rest, and `vs` to detect NaN.
- `scvtf`/`ucvtf` convert integers to floating point; `fcvtzs`/`fcvtzu`
  truncate back like a C cast; `fcvt` converts between float and double.
- FP arguments go in `d0`-`d7`, counted separately from `x0`-`x7`; results in
  `d0`. `d8`-`d15` are callee-saved, the rest are not.
- `printf("%f")` takes a double in a `d` register; floats must be widened first.
- `sqrt`, `pow` and friends need `-lm` on Linux.

## Homework

[exercises.md](exercises.md)
