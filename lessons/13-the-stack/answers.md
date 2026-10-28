# Lesson 13 answers

Programs: [ex3.s](linux/solutions/ex3.s) to [ex7.s](linux/solutions/ex7.s).

## 13.1

| After | sp | memory |
|-------|----|--------|
| `stp x1, x2, [sp, #-16]!` | `0xff0` | `0xff0`: 1, `0xff8`: 2 |
| `str x3, [sp, #-16]!` | `0xfe0` | `0xfe0`: 3 (`0xfe8` unused) |
| `ldr x4, [sp], #16` | `0xff0` | `x4 = 3` |
| `ldp x5, x6, [sp], #16` | `0x1000` | `x5 = 1`, `x6 = 2` |

The values are still in memory below `sp` afterwards, but that memory is free.

## 13.2

1. 16
2. 16
3. 32
4. 112 (100 rounded up)
5. 20 + 16 = 36, rounded up: 48

## 13.8

1. `sub sp, sp, #24` misaligns `sp` (24 is not a multiple of 16), so the first
   `str x0, [sp]` gives `Bus error`. Reserve 32.
2. `add sp, sp, #16` does not match the `sub`. Both must use the same amount
   (32).

With both fixed, it exits with 30.
