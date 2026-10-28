# Lesson 23 (macOS): Floating point

Do [the main lesson](../) first. Everything about
the floating-point registers, IEEE 754, `fmov`, the arithmetic instructions,
`fcmp` and its conditions, and the conversion instructions is identical on
macOS. This page covers only what differs, and walks through each macOS example.

## What is different

| Topic | Linux | macOS |
|-------|-------|-------|
| Loading a constant | `adrp x0, k` / `ldr d0, [x0, :lo12:k]` | `adrp x0, k@PAGE` / `ldr d0, [x0, k@PAGEOFF]` |
| Where constants live | `.section .rodata` | `.section __TEXT,__const` (strings: `__TEXT,__cstring`) |
| `printf("%f", d)` | `d` in `d0` | `d` stored on the stack at `[sp]` |
| Normal (non-variadic) FP arguments | `d0`-`d7` | `d0`-`d7`, the same |
| `d8`-`d15` callee-saved | yes | yes, the same |
| Math library | separate `libm`: link with `-lm` | part of libSystem: nothing to add |
| Function names | `sqrt`, `pow`, `printf` | `_sqrt`, `_pow`, `_printf` |

### `printf` and doubles: the stack again

You met Apple's variadic rule in lesson 16: every argument after the format
string goes on the stack, in 8-byte slots, in order. Doubles are no exception.
Integers and doubles share the same sequence of slots: there is no separate
count as there is with registers.

```c
printf("scale(%ld, %f) = %f\n", 3L, 1.25, s);
```

| Where | Linux | macOS |
|-------|-------|-------|
| format | `x0` | `x0` |
| `3` | `x1` | `[sp]` |
| `1.25` | `d0` | `[sp, #8]` |
| `s` | `d1` | `[sp, #16]` |

The examples reserve the space right after the prologue with
`sub sp, sp, #N` (N a multiple of 16) and give it back with `add sp, sp, #N`
before the epilogue. Store a double with `str d0, [sp, #off]`, an integer with
`str x1, [sp, #off]`.

This rule is **only** for variadic functions. `sqrt(2.0)` and `pow(2.0, 10.0)`
are normal functions and take their arguments in `d0` and `d1` on macOS too.

A `float` is still promoted to `double` before it goes into a variadic slot:
`fcvt d0, s0`, then `str d0, [sp]`.

### No `-lm`

On macOS the math functions are in libSystem, which every program links
against. The Makefiles here are just the one `include` line; `math_lib` and
`ex6` build with the shared rule.

## The examples

Build and run them all natively:

```console
$ cd lessons/23-floating-point/apple-silicon/examples
$ make
$ ./fp_add
1.500000 + 2.250000 = 3.750000
```

Every program prints exactly what its Linux twin prints.

### `fp_add.s`

```asm
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #32             // room for 3 variadic doubles (24 bytes, rounded to 32)

    fmov d0, #1.5
    fmov d1, #2.25
    fadd d2, d0, d1

    str d0, [sp]                // variadic arguments go on the stack,
    str d1, [sp, #8]            //   8 bytes each, in order: a, b, c
    str d2, [sp, #16]
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    bl _printf
    ...
    add sp, sp, #32
    ldp x29, x30, [sp], #16
    ret
```

The arithmetic is unchanged; only the call to `printf` differs. If you forget
the stores and leave the doubles in `d0`-`d2`, `printf` reads whatever happens
to be on the stack and prints garbage.

### `fp_bits.s`

`show_double` passes five variadic values (`d`, `bits`, `sign`, `exp`, `frac`),
so it reserves 48 bytes (40 rounded up to 16) and stores them at `[sp]` through
`[sp, #32]`. `show_float` stores the widened double at `[sp]` and the 32 raw
bits at `[sp, #8]`. It stores all of `x1`: `fmov w1, s0` already zeroed the top
half, so the slot holds a clean 32-bit value.

The constants `0.1` and `0.1f` are in `__TEXT,__const` and loaded with
`ldr d0, [x0, tenth@PAGEOFF]` and `ldr s0, [x0, tenth_f@PAGEOFF]`.

### `fp_ops.s`

`main` is the same as on Linux apart from `@PAGE`/`@PAGEOFF`. The helper
`show(name, value)` stores both variadic arguments:

```asm
show:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16             // two variadic arguments
    str x0, [sp]                // name
    str d0, [sp, #8]            // value
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    bl _printf
    add sp, sp, #16
    ...
```

On Linux the same helper moved `name` to `x1` and left `value` in `d0`. Here the
register numbering does not matter at all: only the slot order does.

### `fp_compare.s`

`fcmp`, `b.vs`, `b.mi`, `b.gt` and the NaN trap behave exactly as on Linux.
`compare` stores `a`, `b` and the word at `[sp]`, `[sp, #8]`, `[sp, #16]`. In
`main`, the three `cset` results are stored as `x1`, `x2`, `x3`: writing `w1`
zeroed the upper half, so storing the full register is safe and fills the
8-byte slot.

### `fp_convert.s`

Every `printf` call has one variadic argument, so `main` reserves 16 bytes once
and stores either `d0` or `x1` at `[sp]` before each call. The conversions
themselves (`scvtf`, `ucvtf`, `fcvtzs`, `fcvtzu`, `fcvt`) are identical,
including the saturating results for `-2.7` and `1e20`.

### `fp_args.s`

`average3`, `scale` and `sum_squares` are normal functions and take their
arguments in registers exactly as on Linux: that part of the convention is
unchanged. Only the `printf` calls differ. `main` saves `d8` in its frame, then
reserves another 32 bytes for variadic slots:

```asm
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]
    sub sp, sp, #32             // room for printf's variadic arguments
    ...
    add sp, sp, #32             // first give back the slots,
    ldr d8, [sp, #16]           // then the saved d8 is at [sp, #16] again
    ldp x29, x30, [sp], #32
```

The order of the epilogue matters: `d8` was saved relative to the `sp` before
the `sub`, so add the 32 back before loading it.

### `math_lib.s`

```asm
    fmov d0, #2.0               // sqrt(2.0): not variadic, so d0 as usual
    bl _sqrt                    // result in d0
    str d0, [sp]
    adrp x0, f_sqrt@PAGE
    add x0, x0, f_sqrt@PAGEOFF
    bl _printf
```

`_sqrt`, `_pow` and `_floor` take `d0`/`d1` and return `d0`. No `-lm`.

### `newton.s`

`newton_sqrt` saves `d8`-`d11` and `x19` with `stp`/`str` at the top of its
frame, then `sub sp, sp, #16` for the two `printf` arguments. Each step stores
`step` at `[sp]` and `x` at `[sp, #8]`. Notice it stores `d9` (where `x` is
kept), not `d0`: it could store either, since both hold the new `x`.

### `stats.s`

`mean` and `stddev` are unchanged. `main` stores `8` and then each double at
`[sp]` before its `printf`.

## Exercises

Do the exercises in [the main lesson](../exercises.md)
as macOS programs, in `lessons/23-floating-point/apple-silicon/work/` or wherever you
like. The macOS solutions are in [solutions/](solutions/). The written answers
(23.1, 23.2) are the same on both platforms: see
[the main solutions README](../answers.md).

Things to watch in the macOS solutions:

- `ex3.s`, `ex4.s`, `ex9.s` mix an integer and a double in one `printf`. On
  macOS both go on the stack, in the order the format string names them.
- `ex5.s` prints three doubles with `%g`: three slots.
- `ex6.s` calls `_sqrt` and needs no Makefile rule.
- `ex8.s` keeps its table of string pointers in `.data` with `.quad s1, s2, ...`,
  exactly as on Linux.
