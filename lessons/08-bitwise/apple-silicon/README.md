# Lesson 08 on macOS: Bits

Read [the main lesson](../README.md) first. All the bit
instructions, logical-immediate rules, shifts, shifted operands, bit-field
instructions, and `clz`/`rbit`/`rev` are **identical** on your Mac. The
examples differ only in the lesson 04 boilerplate (`_main`, `x16 = 1`,
`svc #0x80`).

```console
$ cd lessons/08-bitwise/apple-silicon/examples && make
$ ./masks; echo $?
140
$ ./shifts; echo $?
252
```

## Seeing bits in lldb

Binary output is the most useful view for this lesson:

```console
$ lldb ./logic
(lldb) b main
(lldb) run
(lldb) si -c 7
(lldb) register read -f b x3 x6 x7 x4
```

`-f b` prints binary, `-f x` hex, `-f d` signed decimal.

## Exercises

Do the [main lesson's exercises](../exercises.md) as
macOS programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).

clang's message for a bad logical immediate is
`error: expected compatible register or logical immediate`.
