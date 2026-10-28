# Lesson 12 on macOS: Arrays and pointers

Read [the main lesson](../../lessons/12-arrays-and-pointers/README.md) first.
Array layout, scaling, every addressing mode, pointer arithmetic, row-major
order, and the algorithms are **identical** on your Mac. The examples differ
in the usual boilerplate (`_main`, `x16`/`svc #0x80`, `@PAGE`/`@PAGEOFF`), and
in one assembler quirk.

```console
$ cd apple-silicon/12-arrays-and-pointers/examples && make
$ ./bubble
1 2 3 4 5 6 7 8 9 10
$ echo 23 | ./bsearch
6
```

## A size computed from labels cannot be every immediate

```asm
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
    .equ N, (. - a) / 4
```

On Linux, `N` can be used anywhere a number can. On macOS, clang's assembler
cannot treat a value computed from label addresses as a plain constant in
every instruction: `mov x15, #N` works, but `cmp x10, #N` and
`add x10, x10, #N * 4` fail with
`error: expected compatible register, symbol or integer in range [0, 4095]`.

The fix is to `mov` the value into a register and use the register:

```asm
    mov x15, #N                 // x15 = N
loop:
    cmp x10, x15                // instead of cmp x10, #N
```

The examples and solutions in both tracks are written this way, so they look
the same. Constants defined with plain numbers (`.equ COLS, 4`) work
everywhere.

## Viewing an array in lldb

```console
$ lldb ./bubble
(lldb) b sorted
(lldb) run
(lldb) x/10dw &a
```

Breaking on a label (`sorted`) works in lldb as in gdb.

## Exercises

Do the [main lesson's exercises](../../lessons/12-arrays-and-pointers/exercises.md)
as macOS programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).
