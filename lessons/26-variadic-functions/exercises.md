# Lesson 26 exercises

Work in a `work/` directory inside this lesson's `linux/` folder (on macOS: `apple-silicon/`) (it is git-ignored):

```console
$ mkdir -p work && cd work
```

Copy the example `Makefile` rules you need (an explicit rule per program that
has more than one source file). Try every exercise before you look at
`solutions/`. Written answers are in [answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 26.1 [warm-up]

For each call, write down which register or stack slot holds each argument on
**Linux** AArch64:

1. `printf("%s=%d\n", "x", 5);`
2. `printf("%f %d %f\n", 1.5, 2, 3.5);`
3. `printf("%d %d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6, 7, 8);`
4. `printf("%c %f\n", 'z', 2.0f);` (careful: what type does each argument
   have by the time it is passed?)

## Exercise 26.2 [warm-up]

A function is declared `int f(int a, const char *b, double c, ...);`.

1. What are `__gr_offs` and `__vr_offs` right after `va_start`?
2. Which registers must `f` save in its register save area?
3. `f` is called as `f(1, "s", 2.0, 10, 20, 30, 40, 50, 60, 70)`. Which of the
   seven unnamed ints arrive in registers and which on the stack?
4. Why can `f` not find out on its own that it got seven extra arguments?

## Exercise 26.3 [core]

File: `ex3.s`. Write `int max_of(int n, ...)` that returns the largest of its
`n` int arguments (assume `n >= 1`), and a `main` in the same file that prints:

```
max_of(3, 4, 9, 2) = 9
max_of(1, -5) = -5
max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5) = 9
max_of(5, -10, -20, -3, -40, -50) = -3
```

Use `printf` for the output. Check that the 9-argument call works: three of its
values come from the stack.

## Exercise 26.4 [core]

File: `ex4.s` (plus a copy of `examples/myprintf_test.c` is not needed: write
your own `main` in assembly). Extend `myprintf` with two more conversions:

- `%u`: `unsigned int` in decimal;
- `%b`: `unsigned int` in binary (no leading zeros; 0 prints `0`).

`main` must call your function so that the output is exactly:

```
u: 4294967295 0 42
b: 101 0 11111111 10000000000000000000000000000000
returned 51
```

The third line prints (with the real `printf`) what your function returned for
the second line. The calls are `myprintf("u: %u %u %u\n", -1, 0, 42)` and
`myprintf("b: %b %b %b %b\n", 5, 0, 255, 0x80000000)`.

## Exercise 26.5 [core]

File: `ex5.s`. Write `void die(const char *fmt, ...)` that prints `fatal: `,
then the formatted message, then a newline, all to `stderr`, and then calls
`exit(3)`. Use `vfprintf`. `main` calls

```c
die("cannot open %s (attempt %d of %d, waited %.1f s)", "data.txt", 3, 5, 1.5);
```

Check:

```console
$ ./ex5
fatal: cannot open data.txt (attempt 3 of 5, waited 1.5 s)
$ echo $?
3
$ ./ex5 2>/dev/null; echo $?
3
```

## Exercise 26.6 [core]

File: `ex6.s`. Write `char *concat(int n, ...)` that takes `n` strings and
returns a new `malloc`'d string holding all of them joined together. Walk the
arguments **twice**: once to add up the lengths (`strlen`), once to copy
(`strcpy` or `memcpy`). For the second walk, make a copy of the `va_list`
before the first walk (that is what `va_copy` is for). `main` prints

```
[foobarbaz]
[]
[one two three four five six seven eight nine]
```

from `concat(3, "foo", "bar", "baz")`, `concat(0)` and a call with the nine
strings `"one", " two", " three", ...` (each after the first starts with a
space). Free each result.

## Exercise 26.7 [stretch]

File: `ex7.s`. Write `double average(int n, ...)` that takes `n` doubles and
returns their mean (0.0 if `n` is 0). This needs the VR half of `va_list`:
save `q0`-`q7`, set `__vr_offs = -128`, and implement `va_arg(ap, double)`
(steps of 16 in the save area, 8 on the stack). `main` prints:

```
average of 1.5 2.5 3.5 4.5 = 3.000000
average of 1..10 = 5.500000
average of nothing = 0.000000
```

The second call passes the ten doubles `1.0` to `10.0`: eight in `d0`-`d7`,
two on the stack.

## Exercise 26.8 [stretch]

Written. Look at this function:

```c
void show(int n, ...) {
    va_list ap;
    va_start(ap, n);
    for (int i = 0; i < n; i++) printf("%d ", va_arg(ap, int));
    va_end(ap);
}
```

and the call `show(3, 1, 2.0, 3)`.

1. On Linux, which registers hold the arguments at the call?
2. What does `show` print on Linux? (Think about which slot each `va_arg`
   reads.)
3. On macOS, where are the three variadic arguments? What do you expect it to
   print there? (Read the companion lesson first.)
4. What does this tell you about lying to a variadic function about types?
