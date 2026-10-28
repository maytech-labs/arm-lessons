# Lesson 02: Signed numbers

## Goals

After this lesson you can:

- Read and write negative numbers in **two's complement**, in binary and hex.
- Give the signed range of 8, 16, 32, and 64 bits.
- Negate a number by hand: invert the bits, add 1.
- Explain why the same addition works for signed and unsigned numbers, and
  what wraparound looks like for each.
- Tell **carry** (the unsigned answer is wrong) from **signed overflow** (the
  signed answer is wrong).
- Widen a number with **zero extension** or **sign extension**, and say which
  one C uses when.
- Write a multi-byte number as bytes in memory in **little-endian** order.

## Before you start

[Lesson 01](../01-binary-and-hex/README.md): binary, hex, bit numbers, sizes,
unsigned ranges, and unsigned addition with carries. This lesson is pencil
and paper again; there is nothing to build.

## The problem

In lesson 01 every bit pattern meant a number from 0 up. Eight bits gave 0 to
255. But C has `int x = -5;`, and the CPU has to store that -5 in bits
somehow. There is no "minus" switch, only more bits. We need a rule that
gives some of the patterns a negative meaning.

The obvious idea is to use the top bit as a sign: 0 for plus, 1 for minus,
and the rest for the size. That is called *sign-magnitude*, and almost no CPU
uses it for integers. It has two zeros (+0 and -0), and adding a negative
number needs different circuitry from adding a positive one. There is a much
better rule.

## Two's complement: the top bit is negative

Keep every place value from lesson 01, except one: the **top bit is worth
minus** what it used to be. For 8 bits:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|---|---|---|---|---|---|---|---|
| Unsigned worth | 128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 |
| **Signed worth** | **-128** | 64 | 32 | 16 | 8 | 4 | 2 | 1 |

That is all two's complement is. Read some patterns with it:

```
0000 0101  =                                    4 + 1  =    5
0111 1111  =        64 + 32 + 16 + 8 + 4 + 2 + 1       =  127
1000 0000  = -128                                      = -128
1000 0001  = -128                             + 1      = -127
1111 1110  = -128 + 64 + 32 + 16 + 8 + 4 + 2           =   -2
1111 1111  = -128 + 64 + 32 + 16 + 8 + 4 + 2 + 1       =   -1
```

Some things to notice:

- If the top bit is 0, the number means the same as before. Small positive
  numbers do not change.
- If the top bit is 1, the number is negative. That is why the top bit is
  called the **sign bit**: bit 7 for a byte, bit 31 for a word, bit 63 for a
  doubleword.
- All ones is **-1**, at every size: `0xFF`, `0xFFFF`, `0xFFFFFFFF`,
  `0xFFFFFFFFFFFFFFFF`. You will see `0xff...ff` constantly in a debugger;
  it is very often -1.
- There is only one zero, `0000 0000`.

### Same bits, two meanings

Here is the important idea of this lesson: **the bits do not know whether they
are signed.** `1111 1110` is 254 if you treat it as unsigned and -2 if you
treat it as signed. The register just holds the bits. It is the *instructions
you choose* that decide which meaning to use, just as in C it is the *type*
(`unsigned char` or `signed char`) that decides.

Picture all 256 byte patterns on a clock face:

```
                     0000 0000
                   (0 unsigned, 0 signed)
        1111 1111                    0000 0001
    (255 / -1)                         (1 / 1)
     ...                                  ...
1100 0000 (192 / -64)              0100 0000 (64 / 64)
     ...                                  ...
        1000 0001                    0111 1111
      (129 / -127)                  (127 / 127)
                     1000 0000
                  (128 / -128)
```

Going clockwise adds 1. The unsigned numbers jump from 255 back to 0 at the
top. The signed numbers jump from 127 to -128 at the bottom. Same circle,
different place for the jump.

A quick way to read a signed pattern whose top bit is set: read it as
unsigned and subtract 2ⁿ. `1111 1110` is 254 unsigned, and 254 - 256 = -2.

## Signed ranges

With n bits, the top bit is worth -2ⁿ⁻¹. The most negative number is the top
bit alone (-2ⁿ⁻¹); the most positive is every bit except the top one
(2ⁿ⁻¹ - 1). There is one more negative number than positive, because zero
uses up one of the "top bit 0" patterns.

| Bits | C type | Minimum | Maximum | Minimum in hex | Maximum in hex |
|------|--------|---------|---------|----------------|----------------|
| 8 | `int8_t` | -128 | 127 | `0x80` | `0x7F` |
| 16 | `int16_t` | -32,768 | 32,767 | `0x8000` | `0x7FFF` |
| 32 | `int32_t`, `int` | -2,147,483,648 | 2,147,483,647 | `0x80000000` | `0x7FFFFFFF` |
| 64 | `int64_t`, `long` | -9,223,372,036,854,775,808 | 9,223,372,036,854,775,807 | `0x8000000000000000` | `0x7FFFFFFFFFFFFFFF` |

In C, `<limits.h>` names these: `INT_MIN`, `INT_MAX`, `LONG_MIN`, and so on.
Remember the 32-bit ones roughly: "about plus or minus 2.1 billion".

## Negation: invert and add 1

To find -x, **flip every bit of x, then add 1.**

Find -5 in 8 bits:

```
 5          = 0000 0101
 invert     = 1111 1010      (every 0 becomes 1, every 1 becomes 0)
 add 1      = 1111 1011      = -5
```

Check with the place values: -128 + 64 + 32 + 16 + 8 + 2 + 1 = -5. Correct.

It works in both directions. Find what `1111 1011` is by negating it:

```
 1111 1011
 invert     = 0000 0100
 add 1      = 0000 0101      = 5, so the original was -5
```

That is the easiest way to read a negative number: negate it, read the
positive answer, and put a minus sign in front.

**Why it works.** Add x to its inverse, ~x (C writes "invert the bits" as
`~`). Every column has exactly one 1, so there are no carries and you get all
ones: x + ~x = `1111 1111`, which is -1. So ~x = -1 - x, and ~x + 1 = -x.

### Inverting in hex

To invert a hex digit, subtract it from F: ~5 = A, ~0 = F, ~C = 3. So -5 as a
32-bit word is ~`0x00000005` + 1 = `0xFFFFFFFA` + 1 = `0xFFFFFFFB`.

### Two special cases

- **-0 = 0.** Invert `0000 0000` to get `1111 1111`, add 1, and the carry
  falls off the top: `0000 0000`. Good: one zero.
- **-(-128) = -128** in 8 bits. Invert `1000 0000` to get `0111 1111`, add 1:
  `1000 0000` again. +128 does not fit in a signed byte, so negating the most
  negative number gives itself back. The same happens for `INT_MIN` in 32 bits.

## Addition does not care about signs

Here is the big reason every CPU uses two's complement: **adding the bits
gives the right answer whether you meant them as signed or unsigned.** The
CPU has one `add` instruction (lesson 07), not two.

Add `0000 0101` + `1111 1101` (in 8 bits):

```
carry in:  1  1 1 1 1  1 0 1 0
              0 0 0 0  0 1 0 1
           +  1 1 1 1  1 1 0 1
           --------------------
           1  0 0 0 0  0 0 1 0
```

The carry out of the top falls off, leaving `0000 0010` = 2.

- Read as unsigned: 5 + 253 = 258, which wraps to 258 - 256 = **2**.
- Read as signed: 5 + (-3) = **2**.

Same bits in, same bits out, and both readings are right. Subtraction is
just addition of the negated number: a - b = a + (~b + 1). The CPU's
subtract instruction does exactly that.

## Wraparound, and when the answer is wrong

Fixed-width arithmetic always wraps around the clock face. Whether that gives
a *wrong* answer depends on which meaning you are using.

**Unsigned answers are wrong when there is a carry out of the top bit.** That
is lesson 01's case: 200 + 100 crosses the jump from 255 to 0.

**Signed answers are wrong when the result crosses the jump from 127 to
-128**, in either direction. This is called **signed overflow**. For example,
127 + 1:

```
   0111 1111    (127)
 + 0000 0001    (1)
   ---------
   1000 0000    (-128 signed, 128 unsigned)
```

As unsigned, 127 + 1 = 128: correct, no carry. As signed, 127 + 1 = -128:
wrong. The CPU records both facts in two **flags** (single-bit notes it keeps
after an arithmetic instruction; lesson 09 uses them):

- **C, carry**: set when there is a carry out of the top bit. "The unsigned
  answer did not fit."
- **V, overflow**: set when the signed answer did not fit.

How do you spot signed overflow by hand? Look at the signs:

> Adding two numbers with **different** signs can never overflow. Adding two
> numbers with the **same** sign overflows exactly when the result has the
> **other** sign.

Two positives that add up to a "negative", or two negatives that add up to a
"positive", means overflow. Four 8-bit examples cover every case:

| Bits | Unsigned | Signed | C (carry) | V (overflow) |
|------|----------|--------|-----------|--------------|
| `0x50 + 0x10 = 0x60` | 80 + 16 = 96 ✓ | 80 + 16 = 96 ✓ | 0 | 0 |
| `0x50 + 0x50 = 0xA0` | 80 + 80 = 160 ✓ | 80 + 80 = -96 ✗ | 0 | 1 |
| `0xF0 + 0x20 = 0x10` | 240 + 32 = 16 ✗ | -16 + 32 = 16 ✓ | 1 | 0 |
| `0xD0 + 0x90 = 0x60` | 208 + 144 = 96 ✗ | -48 + -112 = 96 ✗ | 1 | 1 |

Carry and overflow are completely separate. Either, both, or neither can
happen.

### What C says about this

```c
unsigned int u = 4294967295u;   /* UINT_MAX */
u = u + 1;                      /* defined: wraps to 0 */

int i = 2147483647;             /* INT_MAX */
i = i + 1;                      /* UNDEFINED BEHAVIOUR */
```

In C, unsigned arithmetic is defined to wrap. **Signed overflow is undefined
behaviour**: the C standard says nothing about what happens, and optimising
compilers assume it never happens. The CPU itself simply wraps (to
`INT_MIN`) and sets V. When you write assembly you get the CPU's behaviour;
when you translate C, remember the C program was not allowed to overflow in
the first place.

## Making numbers wider: zero extension and sign extension

Often you have a small value (a byte, say) and need it in a bigger space (a
64-bit register). What goes in the new upper bits?

**Zero extension** fills them with 0s. That keeps the *unsigned* value:

```
 1111 1110                      (254 unsigned)
 0000 0000 1111 1110            (still 254)
```

**Sign extension** fills them with copies of the sign bit. That keeps the
*signed* value:

```
 1111 1110                      (-2 signed)
 1111 1111 1111 1110            (still -2)

 0000 0101                      (5)
 0000 0000 0000 0101            (still 5: the sign bit was 0)
```

Why does copying the sign bit work? Widen by one bit at a time. In 8 bits,
a set bit 7 is worth -128. Copy it into a new bit 8: now bit 8 is the top bit,
worth -256, and bit 7 becomes an ordinary bit worth +128. Together they are
-256 + 128 = -128, the same as before. Repeat for each new bit. You can also
just check with "negate and read": `1111 1111 1111 1110` inverted is
`0000 0000 0000 0001`, plus 1 is 2, so it is -2.

In hex, sign extending means filling with `F` if the top hex digit is 8 or
more, and with `0` otherwise: `0xFE` becomes `0xFFFE`, `0xFFFFFFFE`, or
`0xFFFFFFFFFFFFFFFE`; `0x7E` becomes `0x007E`.

The wrong choice gives a wrong answer: zero-extending -2 gives 254, and
sign-extending 254 gives -2.

C picks for you based on the type:

```c
signed char   s = -2;     /* bits 1111 1110 */
unsigned char u = 254;    /* bits 1111 1110: the same byte */

long a = s;               /* sign-extended: a == -2  */
long b = u;               /* zero-extended: b == 254 */
```

AArch64 has instructions for both (`sxtb`, `uxtb`, and loads like `ldrsb` and
`ldrb`, in lessons 11 and 18). You will choose the right one by asking "is
this type signed?"

### Making numbers narrower: truncation

Going the other way, the CPU just **keeps the low bits** and drops the rest.
`0x1234` stored in a byte is `0x34`. In C, `(unsigned char)0x1234 == 0x34`.
If the dropped bits were not all copies of the new sign bit, the value
changes: `(signed char)200` keeps `1100 1000`, which is -56.

## Byte order: little-endian

Memory (lesson 03) is a long row of bytes, each with its own number called its
**address**. A 32-bit word is four bytes, so it takes up four addresses. In
which order do the four bytes go?

Take the word `0x12345678` stored at address `0x1000`. Its bytes are `12`,
`34`, `56`, `78`; `78` is the **least significant byte** (the low end, like
the 1s digit) and `12` the most significant.

**Little-endian** puts the least significant byte at the lowest address:

| Address | `0x1000` | `0x1001` | `0x1002` | `0x1003` |
|---------|----------|----------|----------|----------|
| Byte | `78` | `56` | `34` | `12` |

**Big-endian** would put them the other way round (`12 34 56 78`). Some
older machines and network protocols use it.

AArch64 on Linux and macOS is **little-endian**. So when a tool shows you raw
bytes from memory or from a file, multi-byte numbers look backwards:

- The 32-bit number 42 (`0x0000002A`) is stored as `2a 00 00 00`.
- The 32-bit number -2 (`0xFFFFFFFE`) is stored as `fe ff ff ff`.
- The instruction that `objdump` shows as `d2800540` is stored in the program
  file as the bytes `40 05 80 d2`.

One handy property: the byte at the *lowest* address is always the low
byte, whatever the size. The 64-bit number 42 is `2a 00 00 00 00 00 00 00`,
and reading just its first byte gives 42 too.

Byte order only matters when you look at a number as separate bytes. Inside
a register there is no "order": a register just holds the number.

## C to assembly

| C | Assembly | Notes |
|---|----------|-------|
| `int8_t`, `int16_t`, `int`, `long` | byte, halfword, word, doubleword | signed: top bit worth -2ⁿ⁻¹ |
| `-x` | `neg` (lesson 07) | invert and add 1 |
| `~x` | `mvn` (lesson 08) | invert every bit |
| `a + b`, `a - b`, signed or unsigned | `add`, `sub` (lesson 07) | the same instruction for both |
| `long a = (signed char)c;` | `sxtb` / `ldrsb` (lessons 11, 18) | sign extension |
| `long b = (unsigned char)c;` | `uxtb` / `ldrb` (lessons 11, 18) | zero extension |
| `(unsigned char)x` | keep the low 8 bits | truncation |
| unsigned overflow | carry flag C (lesson 09) | defined in C: wraps |
| signed overflow | overflow flag V (lesson 09) | undefined behaviour in C |
| `-1` as a 32-bit value | `0xFFFFFFFF` | all ones |

## Common mistakes

- **Forgetting the "+1" when negating.** Inverting alone gives -x - 1. If your
  answer is off by one, check this first.
- **Forgetting the width.** "-1 in binary" has no answer until you know how
  many bits: `0xFF`, `0xFFFF`, `0xFFFFFFFF`... Always say the size.
- **Thinking the bits know their sign.** `0xFFFFFFFF` is -1 *or* 4,294,967,295;
  only the code that uses it decides.
- **Confusing carry with overflow.** Carry is about unsigned meaning; overflow
  (V) is about signed meaning. 0x50 + 0x50 overflows but does not carry.
- **Zero-extending a signed value** (or sign-extending an unsigned one). A
  signed byte -1 zero-extended becomes 255.
- **Reading memory bytes in the wrong order.** In a byte dump, `2a 00 00 00`
  is 42, not `0x2A000000`. The first byte is the low byte.
- **Assuming C signed overflow wraps.** The CPU wraps; C does not promise to.

## Recap

- Two's complement: the top bit is worth -2ⁿ⁻¹; all other bits keep their
  usual worth. Top bit 1 means negative.
- n bits hold signed values from -2ⁿ⁻¹ to 2ⁿ⁻¹ - 1 (-128 to 127 for a byte).
- All ones is -1 at every size.
- -x = ~x + 1. Negating the most negative number gives itself.
- Signed and unsigned addition are the same bit operation; only the reading
  differs.
- Carry (C): the unsigned result did not fit. Overflow (V): the signed result
  did not fit. Same-sign inputs, other-sign result means overflow.
- Zero extension keeps unsigned values; sign extension (copy the top bit)
  keeps signed values. Truncation keeps the low bits.
- AArch64 is little-endian: the least significant byte is at the lowest
  address.

## Homework

[exercises.md](exercises.md)
