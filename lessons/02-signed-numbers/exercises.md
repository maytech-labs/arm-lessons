# Lesson 02 exercises

Pencil and paper again. Show your working; the working is the point. If you
keep notes in files, put them in `lessons/02-signed-numbers/work/` (ignored by
git).

Answers, with working, are in [solutions/README.md](solutions/README.md). Try
each exercise before you look.

All numbers are 8 bits unless the exercise says otherwise.

## Exercise 02.1 [warm-up]

Give each 8-bit pattern's value as **unsigned** and as **signed** (two's
complement):

1. `0000 0101`
2. `0111 1111`
3. `1000 0000`
4. `1000 0001`
5. `1111 1110`
6. `1111 1111`
7. `1010 1010`
8. `0x9C`

## Exercise 02.2 [warm-up]

Without looking, write the smallest and largest signed value for 8, 16, 32,
and 64 bits, in hex. Then write the 8-, 16-, and 32-bit ones in decimal too.

## Exercise 02.3 [core]

Write each number in two's complement, in binary and in hex.

8 bits:

1. -1
2. -2
3. -5
4. -42
5. -100
6. -128
7. 100

16 bits:

8. -1
9. -300

32 bits (hex only):

10. -1
11. -16
12. -42

## Exercise 02.4 [core]

Negate each 8-bit value with "invert, add 1". Give the result in binary and
say what number it is.

1. `0000 0111`
2. `1111 1001`
3. `0000 0000`
4. `1000 0000`

For the last one, explain what went wrong and why it had to.

## Exercise 02.5 [core]

For each 8-bit addition, give: the 8-bit result in hex; the sum as unsigned
numbers; the sum as signed numbers; whether the **carry** C is set; whether
**overflow** V is set. Then say which readings (unsigned, signed, both,
neither) gave the right answer.

1. `0x05 + 0x03`
2. `0x05 + 0xFD`
3. `0x7F + 0x01`
4. `0x40 + 0x40`
5. `0xFF + 0x01`
6. `0xC0 + 0xC0`
7. `0x80 + 0x80`
8. `0x90 + 0x70`

## Exercise 02.6 [core]

Do these 8-bit subtractions the way the CPU does: a - b = a + (~b + 1). Give
the result in hex and as a signed number, and say whether there was a carry
out of the top bit.

1. 7 - 3
2. 3 - 7
3. 0 - 1
4. -128 - 1 (that is, `0x80 - 0x01`)

Look at the carries. In which ones was a smaller number subtracted from a
bigger one (thinking unsigned)? What do you notice? (Lesson 09 uses this.)

## Exercise 02.7 [core]

Extension and truncation.

1. Extend each byte to 16 bits, once with zero extension and once with sign
   extension: `0x05`, `0x7F`, `0x80`, `0xFE`.
2. Sign-extend the 16-bit value `0xFFF0` to 32 bits. What number is it,
   before and after?
3. Extend the 32-bit value `0x80000000` to 64 bits both ways. What number is
   each result?
4. Truncate to 8 bits and give the unsigned and signed result: `0x1234`,
   `0x0180`, `0x00C8`.
5. In C, with `signed char s = -1; unsigned char u = 255;`, what are
   `(int)s` and `(int)u`? Write each as a 32-bit hex value.

## Exercise 02.8 [core]

Little-endian byte order.

1. The 32-bit word `0x12345678` is stored at address `0x2000`. Which byte is
   at each of `0x2000`, `0x2001`, `0x2002`, `0x2003`?
2. Write the bytes, lowest address first, for the 32-bit value `0xDEADBEEF`,
   the 16-bit value `0x0102`, the 64-bit value 1, and the 32-bit value -1.
3. A memory dump shows these four bytes, lowest address first. What 32-bit
   number is each, unsigned and signed?
   - `2a 00 00 00`
   - `fe ff ff ff`
   - `00 00 00 80`
4. A program file contains the four bytes `40 05 80 d2`. They are one
   instruction. What 8-digit hex number will `objdump` show for it?

## Exercise 02.9 [stretch]

What does each C expression evaluate to? Assume 32-bit `int` and `unsigned`.
Say which ones are undefined behaviour.

1. `(unsigned char)-1`
2. `(signed char)200`
3. `0u - 1u`
4. `(int)0xFFFFFFFFu` (on every compiler you will use, this keeps the bits)
5. `2147483647 + 1` (both are `int`)
6. `-2147483648` written as `-(2147483647) - 1`, then negated: `-( -2147483647 - 1)`

## Exercise 02.10 [stretch]

Explain in a few sentences each:

1. Why x + ~x is always all ones.
2. Why adding two numbers with different signs can never overflow.
3. Why sign-extending and then truncating back always gives the original
   bits.
4. A 32-bit signed number is stored in memory little-endian. You want to know
   if it is negative by reading a single byte. Which byte do you read (lowest
   address, or highest?), and which bit of it?
