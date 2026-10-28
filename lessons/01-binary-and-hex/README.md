# Lesson 01: Binary and hexadecimal

## Goals

After this lesson you can:

- Explain what the position of a digit means, in any base.
- Convert between decimal, binary, and hexadecimal by hand, in both directions.
- Name the sizes Arm uses: bit, nibble, byte, halfword, word, doubleword.
- Say the largest unsigned number that fits in 8, 16, 32, and 64 bits.
- Add unsigned binary and hex numbers by hand, with carries, and say what
  happens when the answer does not fit.
- Explain why one hex digit is exactly four bits.

## Before you start

[Lesson 00](../00-setup/README.md): you can open a shell. This lesson is
pencil and paper. There are no programs to build. Have some paper ready; you
learn this by doing it, not by reading it.

## Why you need this

A computer stores everything as **bits**: tiny switches that are either off
(0) or on (1). A number in a register, a letter in a string, an instruction
in a program: all of them are patterns of bits. Assembly works directly on
those patterns, so you need to read and write them comfortably.

Long strings of 0s and 1s are hard for people to read, so programmers write
them in **hexadecimal** (base 16) instead. You saw hex in lesson 00:
`d2800020`, `0x400078`. By the end of this lesson those will look like
ordinary numbers.

## Positional notation: what digits mean

Start with something you already know. In the decimal number 4075, each
digit is worth a different amount depending on *where* it is:

| Digit | 4 | 0 | 7 | 5 |
|-------|---|---|---|---|
| Place value | 1000 | 100 | 10 | 1 |
| As a power of 10 | 10³ | 10² | 10¹ | 10⁰ |
| Worth | 4000 | 0 | 70 | 5 |

4000 + 0 + 70 + 5 = 4075. The rightmost place is worth 1, and each place to
the left is worth **ten times** the one to its right. That "ten" is the
**base**. Base 10 has ten digits, 0 to 9.

Nothing about this needs ten. Pick any base *b*: you get *b* digits (0 to
*b* - 1), and places worth 1, *b*, *b*², *b*³, ... from the right. That
is the whole idea of this lesson. Binary is base 2, hex is base 16.

(A reminder: any number to the power 0 is 1. So the rightmost place is
always worth 1, whatever the base.)

## Binary: base 2

Binary has two digits, 0 and 1. Each place is worth twice the one to its
right:

| Place (from the right, starting at 0) | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|----------------------------------------|---|---|---|---|---|---|---|---|
| Power of 2 | 2⁷ | 2⁶ | 2⁵ | 2⁴ | 2³ | 2² | 2¹ | 2⁰ |
| Worth | 128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 |

A binary digit is called a **bit** (*bi*nary digi*t*). The place numbers
along the top are called **bit numbers**: "bit 0" is the rightmost, worth 1.
The rightmost bit is the **least significant bit**; the leftmost is the
**most significant bit**. You will see "bit 31", "bit 63", and so on in
every lesson from now on, so learn to count from 0 on the right.

### Binary to decimal

Write the place values over the bits, then add the places that hold a 1.

Convert `101010`:

```
place value:  32  16   8   4   2   1
bits:          1   0   1   0   1   0
               32 +     8 +     2      = 42
```

So binary 101010 is decimal 42. Convert `11001000`:

```
place value: 128  64  32  16   8   4   2   1
bits:          1   1   0   0   1   0   0   0
             128 +64 +         8               = 200
```

Before reading on, try one yourself: what is `1111` in decimal? (Answer: 8 +
4 + 2 + 1 = 15.)

### Decimal to binary, method 1: take away powers of two

Find the biggest power of two that fits, write a 1 in that place, subtract,
and repeat with what is left. Every place you skip gets a 0.

Convert 42. The powers of two are 1, 2, 4, 8, 16, 32, 64, ...

- 64 is too big. 32 fits: 42 - 32 = 10. Bit for 32 is 1.
- 16 does not fit in 10. Bit for 16 is 0.
- 8 fits: 10 - 8 = 2. Bit for 8 is 1.
- 4 does not fit in 2. Bit for 4 is 0.
- 2 fits: 2 - 2 = 0. Bit for 2 is 1.
- 1: nothing left. Bit for 1 is 0.

Reading the bits from 32 down to 1: `101010`. It matches what we had above.

### Decimal to binary, method 2: divide by two

Divide by 2 again and again, writing down the remainders. Stop when you reach
0. The remainders, read **from the last one to the first one**, are the
binary number.

Convert 42:

```
42 / 2 = 21 remainder 0    <- this is bit 0 (rightmost)
21 / 2 = 10 remainder 1
10 / 2 =  5 remainder 0
 5 / 2 =  2 remainder 1
 2 / 2 =  1 remainder 0
 1 / 2 =  0 remainder 1    <- this is the leftmost bit
```

Reading upwards: `101010`. Same answer.

Why does this work? Dividing by 2 and taking the remainder asks "is the
number odd?", which is exactly the question "is bit 0 a 1?". Dividing by 2
then shifts every bit one place to the right, so the next remainder is the
next bit. Method 2 is easier for big numbers; method 1 is easier to do in your
head once you know the powers of two.

## Powers of two

You will use these constantly. Learn the first eleven by heart (they double
each time, so you can always rebuild them):

| n | 2ⁿ | | n | 2ⁿ |
|---|----|-|---|----|
| 0 | 1 | | 8 | 256 |
| 1 | 2 | | 9 | 512 |
| 2 | 4 | | 10 | 1024 |
| 3 | 8 | | 12 | 4096 |
| 4 | 16 | | 16 | 65,536 |
| 5 | 32 | | 20 | 1,048,576 |
| 6 | 64 | | 32 | 4,294,967,296 (about 4.3 billion) |
| 7 | 128 | | 64 | 18,446,744,073,709,551,616 (about 1.8 × 10¹⁹) |

Useful facts:

- 2¹⁰ = 1024 is close to a thousand. That is why 1024 bytes is called a
  **kibibyte** (KiB), 2²⁰ bytes a mebibyte (MiB), and 2³⁰ a gibibyte (GiB).
  (People often say "kilobyte", "megabyte", "gigabyte" for these.)
- 2¹² = 4096 = 4 KiB is the size of a memory **page**. That turns out to
  matter in lesson 05.
- 2ᵃ × 2ᵇ = 2ᵃ⁺ᵇ. For example 2¹⁶ = 2⁸ × 2⁸ = 256 × 256 = 65,536.

## Bits, bytes, and the names of sizes

Bits are grouped into fixed sizes. These are Arm's names, and they are the
ones this course uses everywhere:

| Name | Bits | Bytes | C type (Linux and macOS, 64-bit ARM) |
|------|------|-------|--------------------------------------|
| bit | 1 | | |
| nibble | 4 | ½ | |
| **byte** | 8 | 1 | `char`, `uint8_t` |
| **halfword** | 16 | 2 | `short`, `uint16_t` |
| **word** | 32 | 4 | `int`, `uint32_t` |
| **doubleword** | 64 | 8 | `long`, `uint64_t`, any pointer |
| quadword | 128 | 16 | `__int128` (lesson 18) |

Careful: **on Arm a "word" is 32 bits.** Intel's documentation calls 16 bits
a word, so you will see the word used differently in other places. In this
course, and in all Arm documentation, word = 32 bits.

The AArch64 registers you meet in lesson 03 are 64 bits wide: each holds one
doubleword. Every instruction is one word (32 bits).

## How many values fit in n bits?

With 1 bit you can write 2 patterns: 0, 1. With 2 bits, 4: 00, 01, 10, 11.
Each extra bit doubles the count, because every old pattern can now have a 0
or a 1 in front. So:

> **n bits can hold 2ⁿ different patterns.**

If the patterns mean the numbers 0, 1, 2, ... (that is, **unsigned**
numbers), the smallest is 0 and the largest is **2ⁿ - 1**: all bits set to 1.
(Not 2ⁿ: counting starts at 0, so 2ⁿ patterns reach up to 2ⁿ - 1.)

| Bits | Name | Unsigned range | Largest in hex |
|------|------|----------------|----------------|
| 8 | byte | 0 to 255 | `0xFF` |
| 16 | halfword | 0 to 65,535 | `0xFFFF` |
| 32 | word | 0 to 4,294,967,295 | `0xFFFFFFFF` |
| 64 | doubleword | 0 to 18,446,744,073,709,551,615 | `0xFFFFFFFFFFFFFFFF` |

Check one: 1111 1111 = 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 255 = 256 - 1.

Negative numbers need a different meaning for the patterns; that is the next
lesson.

## Hexadecimal: base 16

Hex has sixteen digits. After 0 to 9 it runs out of ordinary digits, so it
uses letters:

| Hex digit | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
|-----------|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Decimal | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |

Upper or lower case means the same: `0xFF` = `0xff`. Places are worth 1, 16,
256, 4096, 65,536, ... (powers of 16).

To show a number is hex, C and assembly put **`0x`** in front: `0x2A`. Without
it, `10` means ten; `0x10` means sixteen.

### Hex to decimal

Same method as binary: place values times digits, added up.

Convert `0x2A`:

```
place value:  16    1
digits:        2    A (=10)
               2×16 + 10×1 = 32 + 10 = 42
```

Convert `0x3E8`:

```
place value: 256   16    1
digits:        3    E    8
               3×256 + 14×16 + 8×1 = 768 + 224 + 8 = 1000
```

### Decimal to hex: divide by 16

Same as method 2 for binary, but divide by 16. Remainders 10 to 15 become
the letters A to F.

Convert 1000:

```
1000 / 16 = 62 remainder 8    <- rightmost digit
  62 / 16 =  3 remainder 14 (E)
   3 / 16 =  0 remainder 3    <- leftmost digit
```

Reading upwards: `0x3E8`. Matches.

## Why one hex digit is exactly four bits

One hex digit has 16 possible values. Four bits also have 2⁴ = 16 possible
patterns. So each hex digit matches exactly one group of four bits (a
**nibble**), and you can convert between binary and hex **without going
through decimal at all**:

| Hex | Binary | | Hex | Binary |
|-----|--------|-|-----|--------|
| 0 | 0000 | | 8 | 1000 |
| 1 | 0001 | | 9 | 1001 |
| 2 | 0010 | | A | 1010 |
| 3 | 0011 | | B | 1011 |
| 4 | 0100 | | C | 1100 |
| 5 | 0101 | | D | 1101 |
| 6 | 0110 | | E | 1110 |
| 7 | 0111 | | F | 1111 |

(Why does it work? A hex place is worth 16ᵏ = 2⁴ᵏ, so each hex place lines up
exactly with a block of four binary places. That only works because 16 is a
power of 2. Decimal does not line up with binary, which is why converting
between them takes arithmetic.)

### Binary to hex

Split the bits into groups of four **starting from the right**, pad the
leftmost group with zeros if it is short, and replace each group by its hex
digit.

```
101010         -> 10 1010 -> 0010 1010 -> 2 A -> 0x2A
11001000       -> 1100 1000           -> C 8 -> 0xC8
1101111010101101 -> 1101 1110 1010 1101 -> D E A D -> 0xDEAD
```

### Hex to binary

Replace each hex digit with its four bits:

```
0xA7   -> A    7    -> 1010 0111
0xFF00 -> F    F    0    0    -> 1111 1111 0000 0000
```

This is why programmers like hex: it is a short way to write bits. One byte
is always exactly **two** hex digits (`0x00` to `0xFF`), a halfword four, a
word eight, and a doubleword sixteen. When you see `d2800020` in `objdump`
output, that is eight hex digits: one 32-bit instruction.

To make long binary numbers readable, this course writes them in groups of
four with spaces, like `1100 1000`. The spaces mean nothing.

## Adding unsigned numbers by hand

### In decimal, slowly

Recall how you add on paper. Work from the right. When a column adds up to 10
or more, write the last digit and **carry** 1 into the next column:

```
  carry:   1 1
           4 7 8
         + 2 5 4
         -------
           7 3 2
```

8 + 4 = 12: write 2, carry 1. 7 + 5 + 1 = 13: write 3, carry 1. 4 + 2 + 1 = 7.

### In binary

Exactly the same, but a column carries when it reaches 2. There are only a
few cases:

| Column adds | Write | Carry |
|-------------|-------|-------|
| 0 + 0 | 0 | 0 |
| 0 + 1 | 1 | 0 |
| 1 + 1 (= 2 = binary 10) | 0 | 1 |
| 1 + 1 + carry 1 (= 3 = binary 11) | 1 | 1 |

Add 53 + 26 in 8-bit binary (53 = `0011 0101`, 26 = `0001 1010`):

```
carry in:     0 1 1 0  0 0 0 0
              0 0 1 1  0 1 0 1    (53)
           +  0 0 0 1  1 0 1 0    (26)
           --------------------
              0 1 0 0  1 1 1 1    (79)
```

The top row shows the carry coming *into* each column from the column on its
right. Work it from the right: 1 + 0 = 1; 0 + 1 = 1; 1 + 0 = 1; 0 + 1 = 1;
1 + 1 = 10, write 0 carry 1; 1 + 0 + 1 = 10, write 0 carry 1; 0 + 0 + 1 = 1;
0 + 0 = 0.

Check: 0100 1111 = 64 + 8 + 4 + 2 + 1 = 79, and 53 + 26 = 79.

### In hex

A column carries when it reaches 16. Add `0x3A + 0x29`:

- Right column: A + 9 = 10 + 9 = 19. 19 = 16 + 3: write 3, carry 1.
- Left column: 3 + 2 + 1 = 6.

Answer `0x63` (= 99; and 58 + 41 = 99).

### When the answer does not fit

Registers have a fixed width. Suppose you only have 8 bits and you add
200 + 100:

```
carry in:  1  1 0 0 0  0 0 0 0
              1 1 0 0  1 0 0 0    (200)
           +  0 1 1 0  0 1 0 0    (100)
           --------------------
           1  0 0 1 0  1 1 0 0
           ^
           this 9th bit has nowhere to go
```

The true answer, 300, needs 9 bits. An 8-bit result keeps only the low 8
bits, `0010 1100` = 44. The extra 1 that falls off the left end is the
**carry out**. You lost 256 (the worth of bit 8): 300 - 256 = 44.

So unsigned n-bit addition **wraps around**: the result is the true sum
minus 2ⁿ if the sum does not fit, or in other words the remainder of the true
sum divided by 2ⁿ ("the sum mod 2ⁿ"). Like a car's odometer rolling from 999999 to
000000. The simplest example: 255 + 1 in 8 bits is 0.

This is exactly what C does for unsigned types:

```c
unsigned char a = 200, b = 100;
unsigned char c = a + b;      /* c is 44 */
```

The CPU remembers that a carry fell off the end, in a flag called C (the
carry flag, lesson 09). And you will meet wraparound again in lesson 04, where
a program's exit status is kept mod 256.

## Checking your work

Do the conversions by hand first. Then check them with your shell. These work
in the container's `bash` and in macOS's `zsh`:

```console
$ echo $((2#101010))          # binary to decimal
42
$ echo $((0x3E8))             # hex to decimal
1000
$ printf '%x\n' 1000          # decimal to hex
3e8
$ printf '%X\n' $((2#11001000))   # binary to hex
C8
```

For decimal to binary, use `bc` on the Mac (it is not in the container):

```console
$ echo 'obase=2; 42' | bc
101010
```

## C to assembly

| C | Assembly | Meaning |
|---|----------|---------|
| `42` | `#42` | a decimal constant (you will see `#` in lesson 04) |
| `0x2A` | `#0x2a` | the same number in hex |
| `0b101010` (C23, and a common compiler extension) | `#0b101010` | the same number in binary |
| `unsigned char` / `uint8_t` | byte | 0 to 255 |
| `unsigned short` / `uint16_t` | halfword | 0 to 65,535 |
| `unsigned int` / `uint32_t` | word, a `w` register (lesson 03) | 0 to 2³² - 1 |
| `unsigned long` / `uint64_t` | doubleword, an `x` register (lesson 03) | 0 to 2⁶⁴ - 1 |
| `printf("%x", n)` | | prints n in hex |
| unsigned `a + b` that does not fit | the carry falls off; result is mod 2ⁿ | wraparound |

## Common mistakes

- **Starting place values from 1 instead of 0.** The rightmost bit is bit 0,
  worth 2⁰ = 1. If your conversions come out exactly double, this is why.
- **Grouping bits from the left.** `110101` is `0011 0101` = `0x35`, not
  `1101 01..`. Always group in fours from the right and pad the left.
- **Reading the remainders the wrong way.** In the divide method, the *first*
  remainder is the *rightmost* digit.
- **Treating `10` and `0x10` as the same.** `0x10` is sixteen. Watch for the
  prefix.
- **Off by one on ranges.** 8 bits make 256 patterns, but the largest value is
  255.
- **"Word" means 32 bits on Arm.** Not 16 (Intel) and not "whatever the
  machine's natural size is".
- **Forgetting the carry in the next column**, especially in hex: A + 9 is
  19, which is 0x13, so write 3 and carry 1.

## Recap

- In base *b*, places from the right are worth 1, *b*, *b*², ...; binary is
  base 2, hex is base 16.
- Bit 0 is the rightmost bit. Bits are numbered from 0.
- Convert to decimal by adding place values; convert from decimal by
  repeated division, reading remainders bottom to top.
- One hex digit = four bits = one nibble, so binary and hex convert by
  grouping in fours from the right. A byte is two hex digits.
- Arm sizes: byte 8, halfword 16, word 32, doubleword 64 bits.
- n bits hold 2ⁿ patterns; unsigned values 0 to 2ⁿ - 1 (255, 65,535,
  about 4.3 billion, about 1.8 × 10¹⁹).
- Unsigned addition that does not fit loses the carry out of the top bit: the
  result wraps around mod 2ⁿ.

## Homework

[exercises.md](exercises.md)
