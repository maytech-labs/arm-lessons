# Lesson 10 exercises

Work in `lessons/10-loops/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

If a program never ends, press `Ctrl-c` and debug it. Try each exercise
before looking at the answers: programs are in [linux/solutions/](linux/solutions/),
written answers in [answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 10.1 [warm-up]

Trace this loop by hand. Write down `x0` and `x1` at the label `loop` every
time execution reaches it. What is the exit status? How many times does the
body run? Then check with the debugger (`break loop`, `c`, `p $x0`).

```asm
    mov x0, #0
    mov x1, #4
loop:
    cbz x1, done
    add x0, x0, x1, lsl #1
    sub x1, x1, #1
    b loop
done:
```

What C loop is this?

## Exercise 10.2 [warm-up]

Write `ex2.s` that adds the even numbers 2 + 4 + ... + 20 using a `for` loop
that steps by 2.

Check: exit status `110`.

## Exercise 10.3 [core]

Write `ex3.s` that computes the 13th Fibonacci number (fib(0) = 0,
fib(1) = 1). Count down with `subs`. Write the loop invariant as a comment.

Check: exit status `233`.

## Exercise 10.4 [core]

Write `ex4.s` that prints a rectangle of `#` characters, 4 rows by 6 columns,
with nested loops.

Check: four lines of `######`.

## Exercise 10.5 [core]

Write `ex5.s` that counts the 1 bits in `0xf0f0` by testing the lowest bit and
shifting right until the number is 0.

Check: exit status `8`. Try `0xff` (8) and `1` (1).

## Exercise 10.6 [core]

Write `ex6.s` that clamps `x` to the range 0..100 using **no branches**: only
`cmp` and `csel`.

Check: 150 → `100`, -3 → `0`, 42 → `42`.

## Exercise 10.7 [core]

Write `ex7.s` that finds the integer square root of 200: the largest `r` with
`r * r <= 200`. Count `r` up from 0.

Check: exit status `14`.

## Exercise 10.8 [stretch]

Write `ex8.s` that counts the prime numbers below 100. For each `n`, try
divisors `d` from 2 while `d * d <= n`; `break` out of the inner loop as soon
as a divisor is found.

Check: exit status `25`.

## Exercise 10.9 [stretch]

FizzBuzz, compactly: for `i` from 1 to 15, print one character: `X` if `i`
is divisible by 15, else `B` if divisible by 5, else `F` if divisible by 3,
else `.`. Then a newline. Write `ex9.s` so that the loop body has **no
branches**: choose the address to print with `csel`.

Check: `..F.BF..FB.F..X`.
