# Lesson 01 solutions

Try each exercise before reading its answer. Where your working differs from
the working here but the answer matches, that is fine: there are several good
ways to do each conversion.

## 01.1

| n | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|----|----|----|----|----|----|----|
| 2ⁿ | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 | 256 | 512 | 1024 | 2048 | 4096 | 8192 | 16384 | 32768 | 65536 |

1. 2¹⁰ = 1024, about a thousand. 2²⁰ = 1,048,576, about a million. 2³² =
   4,294,967,296, about four billion.
2. 2⁸ × 2⁴ = 2¹² = 4096. (Add the powers.)
3. 4 KiB = 4 × 1024 = 4096 bytes.

## 01.2

1. `101` = 4 + 1 = **5**
2. `1111` = 8 + 4 + 2 + 1 = **15**
3. `10000` = **16**
4. `101010` = 32 + 8 + 2 = **42**
5. `1100100` = 64 + 32 + 4 = **100**
6. `1000 0000` = **128**
7. `1100 1000` = 128 + 64 + 8 = **200**
8. `1111 1111` = 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = **255**
9. `10 0000 0000` = 2⁹ = **512**

Notice: a 1 followed by n zeros is 2ⁿ (3, 6, 9), and n ones is 2ⁿ - 1 (2, 8).

## 01.3

Take away powers of two:

1. 6 = 4 + 2 → **`110`**
2. 13 = 8 + 4 + 1 → **`1101`**
3. 42 = 32 + 8 + 2 → **`10 1010`**
4. 100 = 64 + 32 + 4 → **`110 0100`**
5. 127 = 64 + 32 + 16 + 8 + 4 + 2 + 1 → **`111 1111`** (one less than 128)

Divide by two (remainders read bottom to top):

6. 128: 64 r0, 32 r0, 16 r0, 8 r0, 4 r0, 2 r0, 1 r0, 0 r1 → **`1000 0000`**
7. 200: 100 r0, 50 r0, 25 r0, 12 r1, 6 r0, 3 r0, 1 r1, 0 r1 → **`1100 1000`**
8. 255: 127 r1, 63 r1, 31 r1, 15 r1, 7 r1, 3 r1, 1 r1, 0 r1 → **`1111 1111`**
9. 256: eight r0s, then 0 r1 → **`1 0000 0000`** (nine bits!)
10. 1000: 500 r0, 250 r0, 125 r0, 62 r1, 31 r0, 15 r1, 7 r1, 3 r1, 1 r1, 0 r1
    → **`11 1110 1000`**

## 01.4

1. `0x1F` = 1×16 + 15 = **31**
2. `0x2A` = 2×16 + 10 = **42**
3. `0x64` = 6×16 + 4 = **100**
4. `0x7F` = 7×16 + 15 = **127**
5. `0xC8` = 12×16 + 8 = **200**
6. `0xFF` = 15×16 + 15 = **255**
7. `0x100` = 1×256 = **256**
8. `0x3E8` = 3×256 + 14×16 + 8 = 768 + 224 + 8 = **1000**
9. `0xFFFF` = 15×4096 + 15×256 + 15×16 + 15 = **65535** (= 2¹⁶ - 1)
10. `0xBEEF` = 11×4096 + 14×256 + 14×16 + 15 = 45056 + 3584 + 224 + 15 = **48879**

## 01.5

1. 10 → 0 r10 → **`0xA`**
2. 16 → 1 r0; 0 r1 → **`0x10`**
3. 42 → 2 r10 (A); 0 r2 → **`0x2A`**
4. 99 → 6 r3; 0 r6 → **`0x63`**
5. 255 → 15 r15; 0 r15 → **`0xFF`**
6. 256 → 16 r0; 1 r0; 0 r1 → **`0x100`**
7. 500 → 31 r4; 1 r15 (F); 0 r1 → **`0x1F4`**
8. 4096 → 256 r0; 16 r0; 1 r0; 0 r1 → **`0x1000`**
9. 48879 → 3054 r15 (F); 190 r14 (E); 11 r14 (E); 0 r11 (B) → **`0xBEEF`**
10. 65535 → 4095 r15; 255 r15; 15 r15; 0 r15 → **`0xFFFF`**

## 01.6

1. `1010 1111` → A F → **`0xAF`**
2. `110101` → `0011 0101` → **`0x35`**
3. `1110011` → `0111 0011` → **`0x73`**
4. `1 0000 0000` → `0001 0000 0000` → **`0x100`**
5. `1101 1110 1010 1101` → **`0xDEAD`**
6. `0x5` → **`0101`**
7. `0x80` → **`1000 0000`**
8. `0xA7` → **`1010 0111`**
9. `0x3C` → **`0011 1100`**
10. `0xFF00` → **`1111 1111 0000 0000`**

If you got 2 or 3 wrong, you probably grouped from the left. Always group
from the right.

## 01.7

1. Byte 8 bits (1 byte), halfword 16 (2), word 32 (4), doubleword 64 (8).
2. Byte 2 hex digits, word 8, doubleword 16 (one hex digit per 4 bits).
3. 65,535 = `0xFFFF`.
4. `0xFFFFFFFF` (eight Fs).
5. 2¹² = 4096 values; the largest is 4095 = `0xFFF`.
6. 10 bits. 2⁹ = 512 is not enough (it holds up to 511); 2¹⁰ = 1024 holds up
   to 1023. (Exercise 01.3 #10 gave 1000 = `11 1110 1000`: ten bits.)
7. 4 bytes, shown as 8 hex digits, like `d2800020`.

## 01.8

Top row: the carry coming into each column.

1. ```
   carry in:     0 1 1 0  0 0 0 0
                 0 0 1 1  0 1 0 1    (53)
              +  0 0 0 1  1 0 1 0    (26)
                 0 1 0 0  1 1 1 1    (79)
   ```
2. Every column carries: the 1 ripples all the way up.
   ```
   carry in:     1 1 1 1  1 1 1 0
                 0 1 1 1  1 1 1 1    (127)
              +  0 0 0 0  0 0 0 1    (1)
                 1 0 0 0  0 0 0 0    (128)
   ```
3. No column ever has two 1s, so there are no carries at all.
   ```
                 0 1 0 1  0 1 0 1    (85)
              +  0 0 1 0  1 0 1 0    (42)
                 0 1 1 1  1 1 1 1    (127)
   ```
4. ```
   carry in:  1  1 0 0 0  0 0 0 0
                 1 1 0 0  1 0 0 0    (200)
              +  0 1 1 0  0 1 0 0    (100)
              1  0 0 1 0  1 1 0 0    (300 in 9 bits)
   ```
   8-bit result: `0010 1100` = 44. The difference is 300 - 44 = 256 = 2⁸: the
   value of the bit that fell off.
5. ```
   carry in:  1  1 1 1 1  1 1 1 0
                 1 1 1 1  1 1 1 1    (255)
              +  0 0 0 0  0 0 0 1    (1)
              1  0 0 0 0  0 0 0 0    (256 in 9 bits)
   ```
   8-bit result: 0. Again 256 apart.

## 01.9

1. A + 9 = 19 = 16 + 3: write 3, carry 1. 3 + 2 + 1 = 6. **`0x63`** (58 + 41 = 99).
2. F + 1 = 16: write 0, carry 1. 0 + 0 + 1 = 1. **`0x10`** (15 + 1 = 16).
3. F + F = 30 = 16 + 14: write E, carry 1. F + F + 1 = 31 = 16 + 15: write F,
   carry 1. **`0x1FE`** (255 + 255 = 510). 8-bit result: **`0xFE`** (254).
4. F + 1: write 0 carry 1, three times; then 7 + 0 + 1 = 8. **`0x8000`**
   (32767 + 1 = 32768).
5. **`0x10000`** (65535 + 1 = 65536). 16-bit result: **`0x0000`**.

## 01.10

1. Writing a 0 on the right shifts every digit one place left, so every digit
   is worth one base more: in binary the value **doubles** (`101` = 5,
   `1010` = 10); in hex it is **multiplied by 16** (`0x2A` = 42,
   `0x2A0` = 672). Lesson 08 uses this to multiply quickly with shifts.
2. Binary numbers ending in 0 are **even** (bit 0, the only odd place value,
   is clear). Hex numbers ending in 0 are **multiples of 16**.
3. n ones plus 1: every column carries, leaving a 1 followed by n zeros, which
   is 2ⁿ. So n ones = 2ⁿ - 1. It is the largest because the next number up
   needs n + 1 bits.
4. Page **`0x400000`**, distance **`0xB4`** (= 180). 4096 = `0x1000`, so a
   multiple of 4096 is a hex number ending in three 0s. The last three hex
   digits (12 bits) are the distance into the page; set them to 0 to get the
   page. Lesson 05 uses exactly this split to load addresses.
5. 250 + 10 = 260, which wraps to 260 - 256 = **4**. 128 + 128 = 256, which
   wraps to **0**.
