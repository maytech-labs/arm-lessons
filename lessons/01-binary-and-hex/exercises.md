# Lesson 01 exercises

This lesson is pencil and paper. Do every conversion **by hand**, showing your
working, before checking with the shell commands from the lesson's
"Checking your work" section. If you want to keep your working in files, put
them in `lessons/01-binary-and-hex/work/` (ignored by git).

Answers, with working, are in [solutions/README.md](solutions/README.md). Try
each exercise before you look.

## Exercise 01.1 [warm-up]

Without looking at the lesson, write out the powers of two from 2⁰ to 2¹⁶.
Then answer:

1. What are 2¹⁰, 2²⁰, and 2³² (roughly, in words)?
2. 2⁸ × 2⁴ is 2 to the power what? What number is that?
3. How many bytes are 4 KiB?

## Exercise 01.2 [warm-up]

Convert from binary to decimal:

1. `101`
2. `1111`
3. `10000`
4. `101010`
5. `1100100`
6. `1000 0000`
7. `1100 1000`
8. `1111 1111`
9. `10 0000 0000`

## Exercise 01.3 [core]

Convert from decimal to binary. Use the "take away powers of two" method for
the first five and the "divide by two" method for the rest.

1. 6
2. 13
3. 42
4. 100
5. 127
6. 128
7. 200
8. 255
9. 256
10. 1000

## Exercise 01.4 [core]

Convert from hex to decimal:

1. `0x1F`
2. `0x2A`
3. `0x64`
4. `0x7F`
5. `0xC8`
6. `0xFF`
7. `0x100`
8. `0x3E8`
9. `0xFFFF`
10. `0xBEEF`

## Exercise 01.5 [core]

Convert from decimal to hex, by dividing by 16:

1. 10
2. 16
3. 42
4. 99
5. 255
6. 256
7. 500
8. 4096
9. 48879
10. 65535

## Exercise 01.6 [core]

Convert **directly** between binary and hex, without going through decimal.

Binary to hex:

1. `1010 1111`
2. `110101`
3. `1110011`
4. `1 0000 0000`
5. `1101 1110 1010 1101`

Hex to binary (write the answer in groups of four):

6. `0x5`
7. `0x80`
8. `0xA7`
9. `0x3C`
10. `0xFF00`

## Exercise 01.7 [core]

Sizes and ranges.

1. How many bits are in a byte, a halfword, a word, and a doubleword? How many
   bytes is each?
2. How many hex digits does it take to write any byte? Any word? Any doubleword?
3. What is the largest unsigned number in 16 bits, in decimal and in hex?
4. What is the largest unsigned number in 32 bits, in hex?
5. How many different values can a 12-bit field hold? What is the largest?
6. What is the smallest number of bits that can hold the number 1000? (Hint:
   find the first power of two bigger than 1000.)
7. An AArch64 instruction is 32 bits. What is that in bytes, and how many hex
   digits does `objdump` show for it?

## Exercise 01.8 [core]

Add these unsigned 8-bit numbers in binary, showing the carries. Then convert
the inputs and the answer to decimal to check yourself.

1. `0011 0101 + 0001 1010`
2. `0111 1111 + 0000 0001`
3. `0101 0101 + 0010 1010`
4. `1100 1000 + 0110 0100`
5. `1111 1111 + 0000 0001`

For the last two, the answer needs 9 bits. Write the full 9-bit answer, then
the 8-bit answer you would actually get, and say how far apart they are.

## Exercise 01.9 [core]

Add in hex, showing the carries:

1. `0x3A + 0x29`
2. `0x0F + 0x01`
3. `0xFF + 0xFF` (give the full answer, and the 8-bit result)
4. `0x7FFF + 0x0001`
5. `0xFFFF + 0x0001` (give the full answer, and the 16-bit result)

## Exercise 01.10 [stretch]

Patterns. Explain each in one or two sentences.

1. What happens to a binary number's value when you write a `0` on its
   right-hand end? (Try it with `101`.) What about a hex number?
2. What do all binary numbers that end in `0` have in common? And all hex
   numbers that end in `0`?
3. Why is the largest n-bit number always written as n ones? Prove that n ones
   equals 2ⁿ - 1. (Hint: add 1 to it.)
4. A memory address is `0x4000B4`. Which 4 KiB page is it in? That is, what
   is the address rounded down to a multiple of 4096 (`0x1000`)? What is the
   distance from the start of that page? (Hint: look at the last three hex
   digits.)
5. 8-bit unsigned: 250 + 10 = ? What about 128 + 128? Give the 8-bit results.
