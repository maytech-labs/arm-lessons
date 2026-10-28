# Lesson 07 on macOS: Arithmetic

Read [the main lesson](../../lessons/07-arithmetic/README.md) first. Every
arithmetic instruction, every immediate rule, `movz`/`movk`, `w` vs `x`,
signed vs unsigned division, and division by zero giving 0 are **identical**
on your Mac: they are properties of the CPU, not the operating system.

The only differences in the examples are the program boilerplate you already
know from lesson 04: `_main` instead of `_start`, and `exit` as `x16 = 1`,
`svc #0x80`.

```console
$ cd apple-silicon/07-arithmetic/examples && make
$ ./fahrenheit; echo $?
212
$ ./signed_div; echo $?
253
```

## Looking at values in lldb

Several examples say "check in the debugger". In lldb:

```console
$ lldb ./bigconst
(lldb) b main
(lldb) run
(lldb) si -c 4
(lldb) register read x0
      x0 = 0x1122334455667788
```

For signed values, ask for decimal: `register read -f d x3` shows `-3` in
`signed_div`. `p/x $x0` and `p/d $x0` also work.

## `ldr x0, =value`

Works the same on macOS: clang's assembler places the constant in a literal
pool after your code and loads it.

## Exercises

Do the [main lesson's exercises](../../lessons/07-arithmetic/exercises.md) as
macOS programs. All the answers are the same. macOS solutions are in
[solutions/](solutions/).

For exercise 07.1, the error messages are worded differently by clang, for
example `error: expected compatible register, symbol or integer in range
[0, 4095]` for `add x0, x1, #5000`.
