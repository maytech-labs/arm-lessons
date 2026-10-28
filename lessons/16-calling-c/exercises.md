# Lesson 16 exercises

Work in a `work/` directory inside this lesson's `linux/` folder (on macOS: `apple-silicon/`) (it is git-ignored):

```console
$ mkdir -p work && cd work
$ cp ../examples/Makefile .       # the shared rules work from here too
```

Single `.s` programs build with `make exN`. For a C + assembly pair, add a rule
to your Makefile like the `sum3` rule in the lesson, or build by hand with
`gcc -g -o exN exN_main.c exN.s`.

Try every exercise before you look at the solutions. Programs are in
[`linux/solutions/`](linux/solutions/); answers to the written questions are in
[`answers.md`](answers.md).

## Exercise 16.1 [warm-up]

Written.

1. A program's `main` is `mov w0, #300` then `ret`. What does `echo $?` print,
   and why?
2. List, in order, what runs between the kernel starting the program and the
   first instruction of `main`, and what runs after `main` returns.
3. A leaf `main` that only does `mov w0, #0` / `ret` has no prologue. Why is
   that allowed here, when `hello.s` needed one?

## Exercise 16.2 [warm-up]

Write `ex2.s`: a `main` that calls `puts` twice to print

```
Line one
Line two
```

and returns 0. Check: the output above, and `echo $?` prints `0`.

## Exercise 16.3 [core]

Write `ex3.s`, which prints a table of squares with `printf`:

```c
for (int i = 1; i <= 10; i++) printf("%d squared is %d\n", i, i * i);
```

Check: ten lines, from `1 squared is 1` to `10 squared is 100`. Where must `i`
live, and what does `main` have to do before using that register?

## Exercise 16.4 [core]

Written. This function is supposed to print `n` and then return `n + 1`.
Find the three bugs. For each, say what would go wrong when it runs.

```asm
    .global show_and_inc
show_and_inc:
    str     x19, [sp, #-8]!
    mov     x9, x0              // keep n
    mov     x1, x0
    adrp    x0, fmt             // fmt: .asciz "%ld\n"
    add     x0, x0, :lo12:fmt
    bl      printf
    add     x0, x9, #1
    ldr     x19, [sp], #8
    ret
```

## Exercise 16.5 [core]

Write `ex5.s` with a helper function `void show(const char *s)` that prints
`"<s>" has <n> characters` using `strlen` and `printf`. `main` calls it for
`"cat"`, `"assembly"` and `""`. Check:

```
"cat" has 3 characters
"assembly" has 8 characters
"" has 0 characters
```

## Exercise 16.6 [core]

Write `long max3(long a, long b, long c)` in `ex6.s`, and a C file
`ex6_main.c` that declares it and prints:

```
max3(1, 9, 4) = 9
max3(-5, -2, -9) = -2
max3(7, 7, 7) = 7
```

Add a Makefile rule so that `make ex6` builds the pair. (Hint: `csel`.)

## Exercise 16.7 [core]

Write `long sum_array(const long *a, long n)` in `ex7.s`. In `ex7_main.c`,
call it on `long digits[] = {3, 1, 4, 1, 5, 9, 2, 6};` with `n = 8`, then with
`n = 0`. Check:

```
sum = 31
empty sum = 0
```

## Exercise 16.8 [core]

Write `ex8.s`: FizzBuzz for 1 to 15. Print the number with `printf("%d\n", i)`,
or `Fizz` (divisible by 3), `Buzz` (by 5), `FizzBuzz` (by 15) with `puts`.
Check, one per line: `1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz`.

## Exercise 16.9 [stretch]

Write `void print_table(const char *title, const int *values, int n)` in
`ex9.s`. It prints the title with `puts`, then each element as
`  [i] = value`. Note that the elements are `int`s: 4 bytes each, and possibly
negative. Call it from `ex9_main.c` with `{2, 3, 5, 7}` titled `Primes` and
`{-3, 0, 12}` titled `Temperatures`. Check:

```
Primes
  [0] = 2
  [1] = 3
  [2] = 5
  [3] = 7
Temperatures
  [0] = -3
  [1] = 0
  [2] = 12
```

## Exercise 16.10 [stretch]

Written. Put this in `fact.c`:

```c
long fact(long n) {
    if (n <= 1)
        return 1;
    return n * fact(n - 1);
}
```

Run `gcc -S -O0 -fno-asynchronous-unwind-tables -o - fact.c`.

1. Explain every instruction of `fact`. Where does gcc keep `n` while the
   recursive call runs? Is that the same choice you made in lesson 15?
2. Now use `-O2`. What happened to the recursion?
