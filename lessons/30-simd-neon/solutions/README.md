# Lesson 30 answers

Programs: [ex2.s](ex2.s) to [ex5.s](ex5.s).

## 30.1

1. 8 lanes of 16 bits; 2 lanes of 32 bits (only the low 64 bits of `v3`).
2. `v0.s[1]` is bytes 4-7: `0x07060504`. `v0.h[7]` is bytes 14-15: `0x0f0e`.
3. `int` (or `int32_t`/`uint32_t`); `float`.
4. In lane 0 of `v0` (the `s0` register). `fmov w1, s0` or `mov w1, v0.s[0]`.
5. A vector compare produces one result per lane, but there is only one set of
   flags. So it produces a mask instead.
6. Only the low 64 bits (`d8`). The upper 64 bits are caller-saved.

## 30.5

Each channel's sum can reach 16 × 255 = 4080, which does not fit in a byte.
`addv b0, v0.16b` would add in 8 bits and wrap; `uaddlv h0, v0.16b` widens to
16 bits as it adds.

## 30.6

GCC widens the `int`s to `long` lanes (`sxtl`/`sxtl2` or `saddw`), keeps
partial sums in `.2d` lanes, reduces with `addp`, and handles the remainder
with a scalar loop. Unlike `sum_array.s`, it accumulates in 64-bit lanes,
because the C code sums into a `long`: summing in 32-bit lanes could overflow.
It may also unroll, processing two vectors per iteration.
