# Lesson 15 exercises

Work in `lessons/15-calling-convention/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Copy `print_uint` and `print_char` from the examples when you need output.
Try each exercise before looking at the answers: programs are in
[linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 15.1 [warm-up]

For each register, say whether it is caller-saved, callee-saved, or special,
and whether you may assume it is unchanged after `bl f`:

`x0`, `x1`, `x7`, `x8`, `x12`, `x16`, `x18`, `x19`, `x25`, `x28`, `x29`,
`x30`, `sp`

## Exercise 15.2 [warm-up]

This function uses `x9`, `x19`, `x20`, and calls another function. Which
registers must its prologue save? How big is the smallest frame that works?

```asm
f:
    mov x19, x0
    mov x20, x1
    mov x9, #3
    bl g
    add x0, x0, x19
    add x0, x0, x20
    ret
```

## Exercise 15.3 [core]

Write `ex3.s` with a recursive `power(b, e)` (`b^e`, with `b^0 = 1`). Print
`power(3, 10)`.

Check: prints `59049`.

## Exercise 15.4 [core]

Write `ex4.s` with a recursive `sum(a, n)` that adds up an array of `long`s:
`sum(a, 0) = 0`, otherwise `a[0] + sum(a + 1, n - 1)`. Sum
`{3, 1, 4, 1, 5, 9, 2, 6}`.

Check: prints `31`.

## Exercise 15.5 [core]

Write `ex5.s` with a function of **nine** arguments that returns
`1*a1 + 2*a2 + ... + 9*a9`. Call it with 1, 2, ..., 9.

Check: prints `285`.

## Exercise 15.6 [core]

Fix `examples/clobber_bug.s` (as `ex6.s`) in two different ways: once by
choosing a different register, once by saving and restoring `x19`. Which fix
is better, and why?

Check: exit status `3`.

## Exercise 15.7 [stretch]

Write `ex7.s` with a recursive `print_rec(n)` that prints `n` in decimal
**without a buffer**: if `n >= 10`, first print `n / 10` recursively, then
print the last digit with `print_char`. Print 9876543210, 0, and 7.

Check: prints `9876543210 0 7`. How deep does the recursion go for the
largest 64-bit number?

## Exercise 15.8 [stretch]

1. Write a plain recursive `sum_to(n) = n + sum_to(n - 1)` (with
   `sum_to(0) = 0`) and run it for `n = 1000000`. What happens, and why?
   How deep can it go before that happens?
2. Rewrite it as `ex8.s` with an accumulator, `sum_to(n, acc)`, so the
   recursive call is a tail call, and use `b`.

Check: `ex8` prints `500000500000`.
