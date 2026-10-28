# Lesson 30 on macOS: SIMD with NEON

Read [the main lesson](../README.md) first. NEON is
part of the CPU: every instruction, arrangement, and technique in the lesson
is **identical** on your Mac, and Apple's cores have very wide NEON units, so
vector code pays off well. The examples differ only in the lesson 16 rules
(`_main`, `_printf`, `@PAGE`, variadic arguments on the stack).

```console
$ cd lessons/30-simd-neon/apple-silicon/examples && make
$ ./sum_array
sum 190, min 1, max 19
$ ./upper
HELLO, SIMD WORLD! 0123456789 ABC XYZ {}
```

## A printf with eight values

`lanes.s` prints eight halfword lanes. On Linux the first seven go in
`x1`-`x7` and the eighth on the stack. On macOS all eight are variadic, so all
eight go on the stack, and the code is arranged differently: each lane is
moved out with `umov` and stored straight into its stack slot.

## Viewing vector registers in lldb

```console
$ lldb ./lanes
(lldb) b main
(lldb) run
(lldb) si -c 10
(lldb) register read v8
(lldb) register read -f "int32_t[]" v8
      v8 = {11 22 33 44}
```

`-f "uint8_t[]"`, `"int16_t[]"`, `"float32[]"` and so on choose the lane view.

## `.equ` sizes

`saxpy.s` uses a plain `.equ N, 8` rather than `(. - y) / 4`, because it
compares with `cmp x20, #N`; clang cannot use a label-difference value there
(lesson 12's companion explains this).

## Exercises

Do the [main lesson's exercises](../exercises.md) as
macOS programs. The answers are the same. For 30.6, use `clang -O2 -S`: clang
vectorises the same loop, often unrolled further than GCC. macOS solutions are
in [solutions/](solutions/).
