# Lesson 18 on macOS: C's integer types

Read [the main lesson](../../lessons/18-integer-types/README.md) first. Type
sizes (LP64), loads, casts, promotions, mixed comparisons, `umulh`/`smulh`,
128-bit arithmetic, and overflow flags are **identical** on your Mac. The
examples differ only in the lesson 16 rules (`_main`, `_printf`, `@PAGE`,
variadic arguments on the stack). Two ABI details are different.

```console
$ cd apple-silicon/18-integer-types/examples && make
$ ./casts
(int)0x123456789 = 0x23456789
(long)-5 = -5, (long)(unsigned)-5 = 4294967291
(char)300 = 44, (short)0x18000 = -32768
```

## Plain `char` is signed

```console
$ ./char_sign
(char)0xff = -1: char is signed
compiled as: ldrsb (sign-extend)
```

On Linux the same program prints 255 and `ldrb`. C leaves this to each
platform, and Apple chose signed (as on x86). Code that stores bytes above 127
in a plain `char` and compares or widens them behaves differently on the two
systems. When it matters, write `unsigned char` or `signed char`.

You can see the compiler's choice directly:

```console
$ clang -S -O1 -o - char_sign.c | grep ldr
```

## Narrow arguments arrive extended

When a `char`, `short`, or `bool` is passed to a function in a register, Apple
requires the **caller** to extend it to 32 bits (sign- or zero-, by its type).
So on macOS a function receiving a `short` in `w0` may use `w0` directly. On
Linux, the bits above the `short` in `w0` are unspecified and the callee must
`sxth w0, w0` itself.

Portable assembly does both: extend before passing a narrow argument, and
extend after receiving one. It costs one instruction.

## Exercises

Do the [main lesson's exercises](../../lessons/18-integer-types/exercises.md)
as macOS programs. The answers are the same, with one exception in 18.1:
plain `char` is signed here, so `(char)200` would be -56 on macOS but 200 on
Linux (the exercise asks about `signed char`, which is -56 on both). macOS
solutions are in [solutions/](solutions/).
