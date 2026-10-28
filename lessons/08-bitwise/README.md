# Lesson 08: Bits

## Goals

After this lesson you can:

- Use `and`, `orr`, `eor`, `mvn`, `bic` as C's `&`, `|`, `^`, `~`, `& ~`.
- Set, clear, toggle, and test individual bits with masks.
- Shift left, shift right logically and arithmetically, and rotate.
- Use a shifted register as an operand (`add x0, x1, x2, lsl #3`).
- Multiply by constants with shifts and adds.
- Pack and unpack bit fields with `ubfx`, `sbfx`, and `bfi`.
- Count leading zeros and reverse bits or bytes.

## Before you start

You need lesson 01 (binary and hex), 02 (two's complement), and 07
(arithmetic, immediates). Keep a binary/hex table handy: every example here is
easier to follow in binary.

```console
# cd lessons/08-bitwise/examples && make
```

## Bitwise operations work on every bit separately

`and`, `orr`, and `eor` look at each bit position on its own. Bit 0 of the
result depends only on bit 0 of the inputs, bit 1 only on bit 1, and so on.

| a | b | `and` (both) | `orr` (either) | `eor` (exactly one) |
|---|---|--------------|----------------|---------------------|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 1 | 0 | 1 | 1 |
| 1 | 0 | 0 | 1 | 1 |
| 1 | 1 | 1 | 1 | 0 |

`eor` is "exclusive or", C's `^`. `orr` has two r's because `or` would be too
short to stand out, Arm says; just learn the spelling.

`examples/logic.s` does all of them on `a = 0b1100` and `b = 0b1010`:

```asm
    and x3, x1, x2              // x = a & b  = 0b1000 = 8
    orr x6, x1, x2              // y = a | b  = 0b1110 = 14
    eor x7, x1, x2              // z = a ^ b  = 0b0110 = 6
    bic x4, x1, x2              // c = a & ~b = 0b0100 = 4  ("bit clear")
    mvn x5, x1                  // n = ~a     = 0xfffffffffffffff3
```

Work each one out on paper with the table, then check in the debugger.

- **`bic`** ("bit clear") is `a & ~b`: it clears in `a` every bit that is set
  in `b`.
- **`mvn`** ("move not") is C's `~`: it flips every bit, all 64 of them. That
  is why `~0b1100` is not `0b0011` but `0xfffffffffffffff3`.

Do not confuse these with C's `&&`, `||`, and `!`. Those are logical
operators that produce 0 or 1 and need branches (lesson 09).

## Masks: working with one bit

A **mask** is a number with 1s in the positions you care about. Bit `n` alone
is `1 << n`.

| Goal | C | Assembly |
|------|---|----------|
| set bit n | `v \|= 1 << n` | `orr x0, x0, #(1 << n)` |
| clear bit n | `v &= ~(1 << n)` | `and x0, x0, #~(1 << n)` or `bic x0, x0, #(1 << n)` |
| toggle bit n | `v ^= 1 << n` | `eor x0, x0, #(1 << n)` |
| test bit n | `v & (1 << n)` | `and x1, x0, #(1 << n)`: non-zero if set |

The assembler evaluates `#(1 << 3)` and `#~(1 << 0)` itself, so you can write
masks the way you think of them. `examples/masks.s`:

```asm
    mov x0, #5                  // v = 0b0000_0101
    orr x0, x0, #(1 << 3)       // set bit 3:    v = 13
    and x0, x0, #~(1 << 0)      // clear bit 0:  v = 12 (mask is all ones but bit 0)
    eor x0, x0, #(1 << 7)       // toggle bit 7: v = 140
    and x1, x0, #(1 << 2)       // test bit 2:   x1 = 4, so bit 2 is set
```

### Logical immediates

The immediates `and`, `orr`, and `eor` accept follow different rules from
`add`'s 0-4095. They must be a **repeating pattern of a run of 1s**: things
like `0xff`, `0xf0`, `0x0000ffff0000ffff`, `~1`, or `0x5555555555555555`.
Single bits, masks of low bits, and their inverses always work. A value like
`0x1234` does not: put it in a register with `mov` first. Zero is never a
valid logical immediate (`and x0, x0, #0` fails); use `mov x0, #0`.

If the assembler rejects the immediate, load the mask into a register.

## Shifts

| Instruction | C | Effect |
|-------------|---|--------|
| `lsl x0, x1, #n` | `x1 << n` | shift left; zeros come in on the right |
| `lsr x0, x1, #n` | `x1 >> n` on an **unsigned** value | shift right; zeros come in on the left |
| `asr x0, x1, #n` | `x1 >> n` on a **signed** value | shift right; copies of the sign bit come in |
| `ror x0, x1, #n` | (no operator) | rotate right; bits leaving on the right come back on the left |

The shift amount can be a register too: `lsl x0, x1, x2`.

Shifting left by `n` multiplies by 2^n. Shifting right by `n` divides by 2^n,
rounding down. For a negative number, only `asr` keeps it negative, just as
`sdiv` vs `udiv` in lesson 07. `examples/shifts.s` shifts -16 both ways:

```asm
    mov x0, #-16                // s = -16 = 0xfffffffffffffff0
    lsl x1, x0, #2              // a = s << 2 = -64 (0xffffffffffffffc0)
    lsr x2, x0, #2              // b = u >> 2 = 0x3ffffffffffffffc
    asr x3, x0, #2              // c = s >> 2 = -4  (0xfffffffffffffffc)
```

Look at the top bits. `lsr` brought in zeros, so the "negative" number became a
huge positive one. `asr` brought in ones, so it stayed negative.

In C, `>>` on a signed type compiles to `asr` and on an unsigned type to `lsr`
(strictly, C leaves right-shifting negative numbers implementation-defined, but
every compiler for ARM64 uses `asr`). Again, the type decides; in assembly, you
decide.

Note that `asr` rounds toward minus infinity: `-7 >> 1` is -4, while
`-7 / 2` is -3. That is why compilers cannot always replace signed division
with a shift.

## Shifted operands

Most arithmetic and logical instructions can shift their **last** register
operand for free, in the same instruction:

```asm
    add x0, x1, x2, lsl #3      // x0 = x1 + (x2 << 3)
    sub x0, x1, x2, asr #1      // x0 = x1 - (x2 >> 1), signed
    orr x0, x1, x2, lsl #8      // x0 = x1 | (x2 << 8)
```

This is how compilers multiply by small constants without `mul`.
`examples/shiftmul.s`:

```asm
    mov x1, #7                  // x = 7
    add x2, x1, x1, lsl #2      // x2 = x + (x << 2) = x * 5 = 35
    lsl x0, x2, #1              // x0 = x2 << 1 = x * 10 = 70
    lsl x3, x1, #3              // x3 = x << 3 = x * 8 = 56
    sub x3, x3, x1              // x3 = x * 8 - x = x * 7 = 49
```

`x * 5` is `x * 4 + x`; `x * 7` is `x * 8 - x`. You will see this all the time
in compiler output, and in lesson 12 for array indexing.

## A classic trick: powers of two

Subtracting 1 from a number flips its lowest 1 bit and every 0 below it. So
`x & (x - 1)` clears the lowest set bit. If `x` had only one bit set (a power
of two), the result is 0. `examples/pow2.s` tests 64 and 96:

```
 64 = 0b100_0000      96 = 0b110_0000
 63 = 0b011_1111      95 = 0b101_1111
  &   0b000_0000  &      0b100_0000 = 64
```

Similar tricks (`x & -x` isolates the lowest set bit, `(x + 15) & ~15` rounds
up to a multiple of 16) appear in the exercises. The round-up trick in
particular you will need in lesson 13, for the stack.

## Bit fields: `ubfx`, `sbfx`, `bfi`

Often several small values are packed into one number. An RGB565 colour packs
red, green, and blue into 16 bits:

```
bit: 15 14 13 12 11 | 10  9  8  7  6  5 |  4  3  2  1  0
          red (5)   |     green (6)     |     blue (5)
```

In C you extract a field with a shift and a mask, and insert one with a shift
and an or:

```c
unsigned green = (c >> 5) & 0x3f;           // extract 6 bits at bit 5
c = (r << 11) | (g << 5) | b;               // insert
```

AArch64 has single instructions for both:

| Instruction | Meaning |
|-------------|---------|
| `ubfx xd, xn, #lsb, #width` | extract `width` bits of `xn` starting at bit `lsb`; zero-extend |
| `sbfx xd, xn, #lsb, #width` | the same, but sign-extend (the field's top bit is its sign) |
| `bfi xd, xn, #lsb, #width` | insert the low `width` bits of `xn` into `xd` at bit `lsb`; the other bits of `xd` are kept |

`examples/bitfields.s`:

```asm
    mov x4, x3                  // c = blue, in bits 4-0
    bfi x4, x2, #5, #6          // insert the low 6 bits of green at bit 5
    bfi x4, x1, #11, #5         // insert the low 5 bits of red at bit 11
                                //   c = 0xfd0c
    ubfx x0, x4, #5, #6         // extract 6 bits starting at bit 5: green = 40
    ubfx x5, x4, #11, #5        // red again: 31 (unsigned field: 0b11111)
    sbfx x6, x4, #11, #5        // the same 5 bits read as SIGNED: 0b11111 = -1
```

The last line shows the difference between the two extracts: the same 5 bits,
`11111`, are 31 unsigned and -1 signed. C's struct bit fields (lesson 19)
compile to exactly these instructions.

## Counting and reversing

| Instruction | Does | C (gcc builtin) |
|-------------|------|-----------------|
| `clz xd, xn` | count leading zeros: 0 bits above the highest 1 | `__builtin_clzl` |
| `rbit xd, xn` | reverse the order of all 64 bits | |
| `rev xd, xn` | reverse the order of the 8 bytes | `__builtin_bswap64` |

There is no "count trailing zeros" instruction in base AArch64: `rbit` then
`clz` does it. `rev` swaps byte order, which is exactly what you need to turn a
big-endian number (network byte order) into a little-endian one.
`examples/bitcount.s` uses all three.

All of these also work on `w` registers, with 32 as the width:
`rev w0, w1` reverses 4 bytes.

## C to assembly

| C | Assembly |
|---|----------|
| `a & b` | `and xd, xa, xb` |
| `a \| b` | `orr xd, xa, xb` |
| `a ^ b` | `eor xd, xa, xb` |
| `~a` | `mvn xd, xa` |
| `a & ~b` | `bic xd, xa, xb` |
| `a << n` | `lsl xd, xa, #n` |
| `a >> n`, `a` unsigned | `lsr xd, xa, #n` |
| `a >> n`, `a` signed | `asr xd, xa, #n` |
| `a + (b << 3)` | `add xd, xa, xb, lsl #3` |
| `a * 9` | `add xd, xa, xa, lsl #3` |
| `(v >> 5) & 0x3f` | `ubfx xd, xv, #5, #6` |
| `v = (v & ~(0x3f << 5)) \| ((g & 0x3f) << 5)` | `bfi xv, xg, #5, #6` |
| `__builtin_clzl(a)` | `clz xd, xa` |
| `__builtin_bswap64(a)` | `rev xd, xa` |

## Common mistakes

- **`lsr` on a signed value.** A negative number becomes a huge positive one.
  Signed values need `asr`.
- **Expecting `mvn` to flip only the bits you can see.** It flips all 64 (or
  32 for `w`).
- **An invalid logical immediate.** `and x0, x0, #0x1234` fails. Put the mask
  in a register.
- **`bfi` arguments.** It is `#lsb, #width`, not `#msb, #lsb`. And the source
  value comes from the *low* bits of the source register.
- **Using `&` where `&&` was meant** when translating C. Bitwise and logical
  operators are different things.
- **Shifting by 64 or more.** Immediate shifts must be 0-63 (0-31 for `w`).
  With a register amount, only the low 6 bits are used, so shifting by 64
  shifts by 0. (In C it is undefined.)

## Recap

- `and`/`orr`/`eor`/`mvn`/`bic` are `&`/`|`/`^`/`~`/`& ~`, bit by bit.
- Masks: `orr` sets, `bic` (or `and` with `~mask`) clears, `eor` toggles,
  `and` tests.
- Logical immediates must be repeating runs of 1s; otherwise use a register.
- `lsl` multiplies by 2^n; `lsr` divides unsigned; `asr` divides signed
  (rounding down); `ror` rotates.
- The last register operand of most instructions can be shifted for free.
- `ubfx`/`sbfx` extract a bit field, `bfi` inserts one.
- `clz`, `rbit`, `rev` count leading zeros, reverse bits, reverse bytes.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](../../apple-silicon/08-bitwise/README.md) next.
