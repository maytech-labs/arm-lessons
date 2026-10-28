# Lesson 23 solutions: written answers

Programs for exercises 23.3 to 23.9 are in this directory as `exN.s`. Build them
all with `make` (the Makefile adds `-lm` for `ex6`).

## Exercise 23.1

1. `5.0 = 101` in binary `= 1.01 x 2^2`. Sign 0. Exponent field
   `2 + 1023 = 1025 = 0x401`. Fraction `0100...0` = `0x4000000000000`.
   Bits: `0 10000000001 0100...0` = **`0x4014000000000000`**.
2. `0.75 = 0.11` in binary `= 1.1 x 2^-1`. Sign 1. Exponent field
   `-1 + 1023 = 1022 = 0x3fe`. Fraction `1000...0` = `0x8000000000000`.
   Bits: `1 01111111110 1000...0` = **`0xbfe8000000000000`**.
3. `0x40490000` = `0 10000000 10010010000000000000000`. Sign 0. Exponent field
   128, so the power is `128 - 127 = 1`. Mantissa `1.1001001` in binary
   `= 1 + 1/2 + 1/16 + 1/128 = 1.5703125`. Value `1.5703125 x 2 =` **`3.140625`**
   (a float that is close to pi, but not very close).
4. Allowed: `0.5`, `3.0` (`24/16 x 2`), `31.0` (`31/16 x 16`), `-0.25`
   (`16/16 x 2^-2`), `0.1875` (`24/16 x 2^-3`).
   Not allowed: `0.1` (not a short binary fraction), `32.0` and `100.0` (need
   `2^5` or more), `0.0625` (needs `2^-4`), `0.0` (use `fmov d0, xzr`).

## Exercise 23.2

- (a) `x0 = -3`. `fcvtzs` rounds toward zero.
- (b) `x0 = 0`. A negative value converted to unsigned saturates at 0.
- (c) `x0 = 2`. `10.0 / 4.0 = 2.5`, truncated to 2.
- (d) Unordered sets `N Z C V = 0 0 1 1`.
  `b.ge` (N = V): not taken. `b.lt` (N != V): **taken**, which is the trap.
  `b.ne` (Z = 0): **taken**, which matches C, where `NaN != 1.0` is true.
  `b.mi` (N = 1): not taken. Only the first taken branch actually runs, of
  course: the program jumps to `L2`.
- (e) `x1 = 0x3ff0000000000000` (the bits), `x2 = 1` (the converted value).

## Exercise 23.9 (the question)

With `n = 10` the error is about `8.3e-04`; with `n = 100000` about `8.3e-12`.
Each time `n` grows ten times the error shrinks a hundred times: the midpoint
rule's error is proportional to `1 / n^2`. (With very large `n` the rounding
errors of the many additions start to matter, and the improvement stops.)
