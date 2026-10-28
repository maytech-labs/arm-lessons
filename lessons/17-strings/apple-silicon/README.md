# Lesson 17 on macOS: Strings

Read [the main lesson](../README.md) first. C strings,
every function in the lesson, the case bit trick, `itoa`, and `atoi` work
**identically** on your Mac. The examples differ in the lesson 16 rules:

- `_main`, and an underscore on every libc function: `_printf`, `_strlen`,
  `_strcmp`, `_atol`, `_sprintf`, ...
- `@PAGE`/`@PAGEOFF` addresses, and `__TEXT,__const` for read-only data.
- **Variadic arguments on the stack.** Every `printf` and `sprintf` call
  stores its arguments after the format into stack slots first:

```asm
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
```

The registers are still set up exactly as on Linux, so the code before each
call is unchanged; the four lines around the call are what macOS adds. For
`sprintf(buf, fmt, ...)`, the variadic arguments start at the third argument,
so the stores start at `x2`.

```console
$ cd lessons/17-strings/apple-silicon/examples && make
$ ./itoa | head -3
0 in base 10: 0
12345 in base 10: 12345
-42 in base 10: -42
```

## `char` is signed on macOS

On Linux AArch64, C's plain `char` is **unsigned**; on Apple platforms it is
**signed**. A function like `int my_toupper(int c)` receives a `char` promoted
to `int`, so a byte like 0xe9 (é in Latin-1) arrives as 233 on Linux but as
-23 on macOS. The examples here only work with ASCII (0-127), where the two
agree, and `case.s` checks every value 0-255 the same way on both systems.
Lesson 18 shows the difference in detail.

## The overflow example

`overflow.s` relies on `name` and `secret` being next to each other in
`.data`. The macOS linker keeps them in the same order, so it prints the same
three lines. In general, never rely on where the linker puts two variables
relative to each other.

## Exercises

Do the [main lesson's exercises](../exercises.md) as
macOS programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).
