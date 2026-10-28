# Lesson 08 answers

Programs: [ex3.s](linux/solutions/ex3.s) to [ex10.s](linux/solutions/ex10.s).

## 08.1

1. `0b0100_0010`
2. `0b1110_1110`
3. `0b1010_1100`
4. `0b1000_1000`
5. `0b0010_1000` (the two top bits fall off)
6. `0b0001_1001`
7. `0b1111_1001` (the sign bit, 1, is copied in)
8. `0`: every bit is equal to itself. Compilers sometimes use `eor x0, x0, x0`
   to clear a register.

## 08.2

1. `orr x0, x0, #(1 << 12)`
2. `bic x0, x0, #(1 << 4)` (or `and x0, x0, #~(1 << 4)`)
3. `eor x0, x0, #3`
4. `and x0, x0, #0xff`
5. `add x0, x1, x1, lsl #4`
6. `lsr x0, x0, #3`
7. `lsr x0, x0, #3` or `asr x0, x0, #3`: equal for non-negative values. If it
   can be negative, `asr` rounds toward minus infinity (-9 >> 3 = -2) but C's
   `/` rounds toward zero (-9 / 8 = -1). You need `sdiv`, or a correction:
   add 7 to negative values before shifting.

## 08.6

Adding 15 pushes any value that is not already a multiple of 16 past the next
multiple; clearing the low 4 bits then drops it back down onto that multiple.
Clearing low bits rounds down to a multiple of a power of two only, because
"the low 4 bits" is exactly "the remainder mod 16". For 10 there is no such
set of bits.

## 08.8

`-x` is `~x + 1`. Inverting flips every bit; adding 1 carries up through the
trailing 1s (formerly the trailing 0s of `x`) and stops at the first 0, which
was the lowest 1 of `x`. So `x` and `-x` agree only at that one bit: `x & -x`
isolates it. 88 = `0b101_1000`, so the result is `0b1000` = 8.

## 08.9

For negative `x`, `m` is all ones (-1): `x ^ m` is `~x`, and `~x - (-1)` is
`~x + 1` = `-x`. For non-negative `x`, `m` is 0: `x ^ 0 - 0` is `x`.
