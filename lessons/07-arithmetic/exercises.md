# Lesson 07 exercises

Work in `lessons/07-arithmetic/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Results come back as the exit status (0-255). When a value does not fit,
check it in the debugger instead. Try each exercise before looking at the
answers: programs are in [linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 07.1 [warm-up]

Which of these assemble? For each one that does not, say why, and write a
replacement (one or more instructions) that does the intended job.

1. `add x0, x1, #4000`
2. `add x0, x1, #5000`
3. `add x0, x1, #8192`
4. `mul x0, x1, #10`
5. `mov x0, #70000`
6. `sub x0, x1, #-5`
7. `udiv x0, x1, #2`
8. `add x0, w1, w2`

Check your answers by putting each line in a file and running `make`.

## Exercise 07.2 [warm-up]

Write `ex2.s` that computes `(7 + 8) * 3 - 4` and exits with the result.

Check: `./ex2; echo $?` prints `41`.

## Exercise 07.3 [core]

Predict the value of `x0` (as a 64-bit hex number) after each sequence. Then
check in the debugger.

1. `mov x1, #5` / `sub x0, x1, #6`
2. `mov x1, #5` / `neg x0, x1` / `add x0, x0, #10`
3. `mov x1, #20` / `mov x2, #3` / `udiv x0, x1, x2`
4. `mov x1, #20` / `mov x2, #3` / `udiv x3, x1, x2` / `msub x0, x3, x2, x1`
5. `movz x0, #0xabcd, lsl #16`
6. `mov x0, #-1` / `movk x0, #0, lsl #32`
7. `mov w0, #-1`
8. `mov x0, #-1` / `add w0, w0, #1`

## Exercise 07.4 [core]

Write `ex4.s` that builds the constant `0xdeadbeefcafef00d` in `x0` using
`movz` and `movk`, then exits.

Check: the exit status is `13` (the low byte `0x0d`), and in the debugger
`p/x $x0` just before the `svc` shows `0xdeadbeefcafef00d`.

## Exercise 07.5 [core]

7384 seconds is how many hours, minutes, and seconds? Write `ex5.s` that
computes `h`, `m`, and `s` from 7384 using division and remainders only (no
working it out by hand), and exits with `h * 100 + m * 10 + s`.

Check: `./ex5; echo $?` prints `234` (2 h, 3 min, 4 s).

## Exercise 07.6 [core]

Write `ex6.s` that evaluates `3x² + 2x + 1` at `x = 5`, using exactly two
`madd` instructions and no `mul`. (Hint: `3x² + 2x + 1 = (3x + 2)·x + 1`.)

Check: exit status `86`.

## Exercise 07.7 [core]

In C, `-17 / 5` is `-3` and `-17 % 5` is `-2`. Write `ex7.s` that computes both
with `sdiv` and `msub` and exits with the remainder.

Check: exit status `254` (the low byte of -2). In the debugger, the quotient
register shows -3. What does `udiv` give for the same registers, and why?

## Exercise 07.8 [stretch]

Write `ex8.s` that computes the sum of the decimal digits of 2024 (2+0+2+4 = 8)
using only `udiv`, `msub`, `add`, and `mov`. You do not have loops yet, so
repeat the steps.

Check: exit status `8`. Change the number to 9999: the answer is 36.

## Exercise 07.9 [stretch]

Compute 100000 × 100000 twice in `ex9.s`: once with `w` registers (like a C
`unsigned int`) and once with `x` registers (like `unsigned long`). 100000
does not fit in a single `mov`'s 16 bits, so build it with `movz`/`movk`.

Check in the debugger just before the `svc`: the 64-bit result is
`0x2540be400` (10 000 000 000); the 32-bit result is `0x540be400`. Explain the
relationship between the two.
