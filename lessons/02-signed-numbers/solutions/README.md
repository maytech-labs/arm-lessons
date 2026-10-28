# Lesson 02 solutions

Try each exercise before reading its answer.

## 02.1

| Pattern | Unsigned | Signed | Working (signed) |
|---------|----------|--------|------------------|
| `0000 0101` | 5 | 5 | top bit 0: same as unsigned |
| `0111 1111` | 127 | 127 | top bit 0 |
| `1000 0000` | 128 | -128 | -128 |
| `1000 0001` | 129 | -127 | -128 + 1 |
| `1111 1110` | 254 | -2 | 254 - 256 |
| `1111 1111` | 255 | -1 | 255 - 256 |
| `1010 1010` | 170 | -86 | -128 + 32 + 8 + 2, or 170 - 256 |
| `0x9C` = `1001 1100` | 156 | -100 | -128 + 16 + 8 + 4, or 156 - 256 |

## 02.2

| Bits | Minimum | Maximum |
|------|---------|---------|
| 8 | `0x80` = -128 | `0x7F` = 127 |
| 16 | `0x8000` = -32,768 | `0x7FFF` = 32,767 |
| 32 | `0x80000000` = -2,147,483,648 | `0x7FFFFFFF` = 2,147,483,647 |
| 64 | `0x8000000000000000` | `0x7FFFFFFFFFFFFFFF` |

The pattern: minimum is the top bit alone; maximum is every bit but the top.

## 02.3

Method for each negative number: write the positive, invert, add 1.

1. -1: 1 = `0000 0001` → `1111 1110` → **`1111 1111`** = `0xFF`
2. -2: 2 = `0000 0010` → `1111 1101` → **`1111 1110`** = `0xFE`
3. -5: 5 = `0000 0101` → `1111 1010` → **`1111 1011`** = `0xFB`
4. -42: 42 = `0010 1010` → `1101 0101` → **`1101 0110`** = `0xD6`
5. -100: 100 = `0110 0100` → `1001 1011` → **`1001 1100`** = `0x9C`
6. -128: **`1000 0000`** = `0x80` (the top bit alone)
7. 100: positive, so just **`0110 0100`** = `0x64`
8. -1 (16 bits): **`1111 1111 1111 1111`** = `0xFFFF`
9. -300 (16 bits): 300 = `0000 0001 0010 1100` → `1111 1110 1101 0011` →
   **`1111 1110 1101 0100`** = `0xFED4`
10. -1 (32 bits): **`0xFFFFFFFF`**
11. -16: 16 = `0x00000010` → invert (F minus each digit) `0xFFFFFFEF` → +1 →
    **`0xFFFFFFF0`**
12. -42: 42 = `0x0000002A` → `0xFFFFFFD5` → **`0xFFFFFFD6`**

Notice 11 and 12: the low byte is the same as the 8-bit answer, with `FF`s in
front. That is sign extension (later in the lesson).

## 02.4

1. `0000 0111` (7) → invert `1111 1000` → +1 → **`1111 1001`** = -7.
2. `1111 1001` (-7) → invert `0000 0110` → +1 → **`0000 0111`** = 7. (The
   reverse of the first one.)
3. `0000 0000` → invert `1111 1111` → +1 → `1 0000 0000`, and the carry falls
   off: **`0000 0000`** = 0. Zero is its own negative.
4. `1000 0000` (-128) → invert `0111 1111` → +1 → **`1000 0000`** = -128
   again. The right answer, +128, is bigger than the largest signed byte (127),
   so it cannot be represented. There are 128 negative patterns but only 127
   positive ones, so one negative number has no positive partner.

## 02.5

| # | Bits | Unsigned | Signed | C | V | Right readings |
|---|------|----------|--------|---|---|----------------|
| 1 | `0x05 + 0x03 = 0x08` | 5 + 3 = 8 | 5 + 3 = 8 | 0 | 0 | both |
| 2 | `0x05 + 0xFD = 0x02` | 5 + 253 = 2 | 5 + -3 = 2 | 1 | 0 | signed only |
| 3 | `0x7F + 0x01 = 0x80` | 127 + 1 = 128 | 127 + 1 = -128 | 0 | 1 | unsigned only |
| 4 | `0x40 + 0x40 = 0x80` | 64 + 64 = 128 | 64 + 64 = -128 | 0 | 1 | unsigned only |
| 5 | `0xFF + 0x01 = 0x00` | 255 + 1 = 0 | -1 + 1 = 0 | 1 | 0 | signed only |
| 6 | `0xC0 + 0xC0 = 0x80` | 192 + 192 = 128 | -64 + -64 = -128 | 1 | 0 | signed only |
| 7 | `0x80 + 0x80 = 0x00` | 128 + 128 = 0 | -128 + -128 = 0 | 1 | 1 | neither |
| 8 | `0x90 + 0x70 = 0x00` | 144 + 112 = 0 | -112 + 112 = 0 | 1 | 0 | signed only |

Checks with the sign rule: 3 and 4 add two positives and get a negative (V);
7 adds two negatives and gets a non-negative (V); 6 adds two negatives and
gets a negative (no V); 2, 5, and 8 have different signs (never V).

## 02.6

1. 7 - 3: ~3 + 1 = `0xFC` + 1 = `0xFD`. 7 + `0xFD` = `0x104` → **`0x04`** = 4.
   Carry **1**.
2. 3 - 7: ~7 + 1 = `0xF9`. 3 + `0xF9` = **`0xFC`** = -4. Carry **0**.
3. 0 - 1: ~1 + 1 = `0xFF`. 0 + `0xFF` = **`0xFF`** = -1. Carry **0**.
4. `0x80 - 0x01`: 0x80 + `0xFF` = `0x17F` → **`0x7F`** = 127. Carry **1**.
   (And as a signed sum, -128 - 1 = 127 is wrong: V is set too.)

The carry was 1 exactly when a ≥ b as unsigned numbers (7 ≥ 3, and 128 ≥ 1),
and 0 when the subtraction had to "borrow" (3 < 7, 0 < 1). So after a
subtraction, carry set means "no borrow". Lesson 09's unsigned comparisons
are built on this.

## 02.7

1. | Byte | Zero-extended | Sign-extended |
   |------|---------------|---------------|
   | `0x05` | `0x0005` (5) | `0x0005` (5) |
   | `0x7F` | `0x007F` (127) | `0x007F` (127) |
   | `0x80` | `0x0080` (128) | `0xFF80` (-128) |
   | `0xFE` | `0x00FE` (254) | `0xFFFE` (-2) |

   When the top bit is 0, both give the same answer.
2. `0xFFF0` is -16. Sign-extended: `0xFFFFFFF0`, still -16.
3. Zero extension: `0x0000000080000000` = 2,147,483,648. Sign extension:
   `0xFFFFFFFF80000000` = -2,147,483,648.
4. | Value | Low byte | Unsigned | Signed |
   |-------|----------|----------|--------|
   | `0x1234` | `0x34` | 52 | 52 |
   | `0x0180` | `0x80` | 128 | -128 |
   | `0x00C8` | `0xC8` | 200 | -56 |
5. `(int)s` is sign-extended: -1 = `0xFFFFFFFF`. `(int)u` is zero-extended:
   255 = `0x000000FF`. The same byte `0xFF`, two different results, because
   of the type.

## 02.8

1. `0x2000`: `78`, `0x2001`: `56`, `0x2002`: `34`, `0x2003`: `12`.
2. - `0xDEADBEEF`: `ef be ad de`
   - `0x0102` (16-bit): `02 01`
   - 1 (64-bit): `01 00 00 00 00 00 00 00`
   - -1 (32-bit): `ff ff ff ff` (all bytes are the same, so order does not show)
3. - `2a 00 00 00` = `0x0000002A` = 42 unsigned and 42 signed.
   - `fe ff ff ff` = `0xFFFFFFFE` = 4,294,967,294 unsigned, -2 signed.
   - `00 00 00 80` = `0x80000000` = 2,147,483,648 unsigned, -2,147,483,648 signed.
4. Reverse the bytes: **`d2800540`**. (That is `mov x0, #42`, which you will
   write in lesson 04.)

## 02.9

1. 255. Converting to an unsigned type is defined to wrap: -1 + 256.
2. -56 with gcc and clang: the byte `0xC8` read as signed. (The C standard
   calls converting an out-of-range value to a signed type
   *implementation-defined*; every compiler you will use keeps the bits.)
3. 4,294,967,295 (`UINT_MAX`). Defined: unsigned arithmetic wraps.
4. -1. Same rule as 2: implementation-defined, and gcc and clang keep the bits.
5. **Undefined behaviour**: signed overflow. The CPU would produce `0x80000000`
   (`INT_MIN`), but the C program is simply wrong. Compilers usually warn.
6. **Undefined behaviour**: negating `INT_MIN` overflows (exercise 02.4 #4 at
   32 bits). The CPU would give `INT_MIN` back.

## 02.10

1. Wherever x has a 1, ~x has a 0, and the other way round. So every column of
   x + ~x adds 1 + 0 or 0 + 1, which is 1 with no carry. The result is all ones.
2. If one number is positive (or zero) and the other is negative, the sum lies
   between them: it is no bigger than the positive one and no smaller than the
   negative one. Both of those fit in the range, so the sum does too.
3. Sign extension only adds bits above the original ones and never changes
   the original bits. Truncation removes exactly those added bits.
4. Read the byte at the **highest** address (the fourth byte): little-endian
   puts the most significant byte last. The sign is its **bit 7** (which is
   bit 31 of the word).
