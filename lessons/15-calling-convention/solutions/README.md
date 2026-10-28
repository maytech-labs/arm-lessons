# Lesson 15 answers

Programs: [ex3.s](ex3.s) to [ex8.s](ex8.s).

## 15.1

| Register | Kind | Unchanged after `bl f`? |
|----------|------|-------------------------|
| `x0`, `x1` | argument/result, caller-saved | no (they hold the result) |
| `x7` | argument, caller-saved | no |
| `x8` | indirect result, caller-saved | no |
| `x12` | temporary, caller-saved | no |
| `x16` | intra-call scratch, caller-saved | no (may change even before `f` starts) |
| `x18` | platform register | never use it |
| `x19`, `x25`, `x28` | callee-saved | yes |
| `x29` | frame pointer, callee-saved | yes |
| `x30` | link register | no: `bl` itself sets it. After `f` returns it holds the address `bl` put there, so save it first if you need yours |
| `sp` | callee-saved | yes |

## 15.2

`x29`, `x30` (it calls `g`), `x19`, and `x20` (callee-saved and used). Not `x9`:
it is caller-saved, and `f` does not need it after the call anyway. Four
registers × 8 bytes = 32 bytes. The fixed function:

```asm
f:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    ...
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
```

## 15.6

Using a caller-saved register (`x9`) is better: it is a temporary, so it
should live in a temporary register, and then nothing needs saving. Saving and
restoring `x19` costs two memory accesses and is only worth it when a value
must survive a call.

## 15.7

The largest 64-bit number, 18446744073709551615, has 20 digits: 20 levels.

## 15.8

1. It crashes with `Segmentation fault` (exit status 139): a million frames of
   32 bytes is about 32 MB, and the stack is 8 MiB. With 32-byte frames it can
   go roughly 8 MiB / 32 B ≈ 260 000 levels (a bit less, since the stack also
   holds other things).
2. See [ex8.s](ex8.s). With the accumulator nothing remains to do after the
   recursive call, so it is a `b` and uses no stack at all.
