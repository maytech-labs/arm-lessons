# Lesson 12 answers

Programs: [ex3.s](ex3.s) to [ex8.s](ex8.s).

## 12.1

1. `0x1005`
2. `0x1014` (5 × 4 = 20 = 0x14)
3. `0x1028` (5 × 8 = 40 = 0x28)
4. `0x103c`: element 2 × 6 + 3 = 15, times 4 = 60 = 0x3c
5. `0x100c`
6. `5`: (0x1018 - 0x1004) / 4 = 20 / 4

## 12.2

1. `ldr x0, [x9, x10, lsl #3]`
2. `ldrh w0, [x9, x10, lsl #1]`
3. `ldrsb x0, [x9, x10]`
4. `str w0, [x9, x10, lsl #2]`
5. `ldr x0, [x11], #8`
6. `add x11, x9, x10, lsl #2`

## 12.3

With `ldr w11` the upper 32 bits of `x11` are zero, so -1 becomes
`0x00000000ffffffff`, a positive 64-bit number, and nothing counts as
negative: it prints `0`. Either sign-extend with `ldrsw`, or compare the
32-bit register: `cmp w11, #0`.
