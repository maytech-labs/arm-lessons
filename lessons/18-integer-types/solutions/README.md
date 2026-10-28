# Lesson 18 answers

Programs: [ex3.s](ex3.s) to [ex8.s](ex8.s).

## 18.1

1. 4, 8, 8, 8
2. 65535
3. -2147483648
4. 255
5. -56 (200 - 256)
6. -1: the low 32 bits are `0xffffffff`
7. -1 (sign-extended) and 4294967295 (zero-extended)
8. 0 (false): -1 converts to `unsigned`, the largest value. And 1 (true):
   `0u` converts to `long`, which can hold every `unsigned`, so the comparison
   is signed.

## 18.2

1. `ldrsh x0, [x1]`
2. `ldrb w0, [x1]`
3. `sxtw x0, w2`
4. `mov w0, w2` (or `uxtw x0, w2`)
5. `sxth w0, w2`
6. `add x0, x3, w2, sxtw`
7. `ldr x0, [x1, w2, sxtw #3]`

## 18.3

`a + b = (a ^ b) + 2 * (a & b)`: the bits both numbers have are counted twice,
the bits only one has are counted once. Halving gives
`(a & b) + (a ^ b) / 2`, and neither part can overflow.

## 18.6

With `ldrb`, each negative byte `b` is read as `b + 256`. Three bytes are
negative (-1, -2, -128), so the wrong sum is -4 + 3 × 256 = 764.
