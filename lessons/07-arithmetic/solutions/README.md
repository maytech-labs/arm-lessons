# Lesson 07 answers

Programs: [ex2.s](ex2.s), [ex4.s](ex4.s), [ex5.s](ex5.s), [ex6.s](ex6.s),
[ex7.s](ex7.s), [ex8.s](ex8.s), [ex9.s](ex9.s).

## 07.1

1. OK: 4000 is in 0-4095.
2. Error: 5000 is above 4095 and is not a multiple of 4096. Use
   `mov x2, #5000` / `add x0, x1, x2`, or `add x0, x1, #4096` /
   `add x0, x0, #904`.
3. OK: 8192 = 2 shifted left by 12.
4. Error: `mul` takes no immediate. `mov x2, #10` / `mul x0, x1, x2`.
5. Error: 70000 = 0x11170 needs two 16-bit chunks.
   `movz x0, #0x1170` / `movk x0, #0x1, lsl #16`.
6. OK: the assembler turns it into `add x0, x1, #5`.
7. Error: division takes no immediate. `mov x2, #2` / `udiv x0, x1, x2`.
8. Error: you cannot mix `x` and `w` registers in one instruction.

## 07.3

1. `0xffffffffffffffff` (5 - 6 = -1)
2. `0x0000000000000005` (-5 + 10)
3. `0x0000000000000006` (20 / 3 rounds toward zero)
4. `0x0000000000000002` (20 - 6 * 3)
5. `0x00000000abcd0000`
6. `0xffff0000ffffffff`: `movk` with `lsl #32` replaces bits 32-47 only. A
   common wrong answer is `0xffffffff0000ffff`, which zeroes bits 16-31 instead.
7. `0x00000000ffffffff`: writing `w0` clears the top half of `x0`.
8. `0x0000000000000000`: `w0` was `0xffffffff`; adding 1 wraps to 0 in 32 bits,
   and the write to `w0` clears the top half.

## 07.7

`udiv` treats `0xffffffffffffffef` as 18446744073709551599 and divides it by
5, giving 3689348814741910319. The same bits mean -17 only if you choose a
signed instruction.

## 07.9

`0x2540be400` truncated to 32 bits is `0x540be400`: the 32-bit multiply keeps
only the low 32 bits of the true product. That is 1410065408 as an `unsigned
int`, which is 10 000 000 000 mod 2^32.
