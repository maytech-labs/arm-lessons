# Lesson 18: C's integer types

## Goals

After this lesson you can:

- Give the size and range of every C integer type on ARM64.
- Choose `w` or `x` registers and the right load for each type.
- Translate casts: truncation, sign extension, zero extension.
- Predict C's integer promotions and "usual arithmetic conversions", and see
  them in the instructions a compiler must emit.
- Get the high half of a 64 × 64-bit product with `umulh`/`smulh`.
- Do 128-bit addition and subtraction with the carry flag.
- Detect signed and unsigned overflow.

## Before you start

You need lesson 02 (two's complement, extension), 07 (arithmetic), 09 (flags),
11 (loads of every size), and 16 (calling `printf`). This lesson is about the
part of C that most often surprises people: what happens to the bits when
types meet.

```console
# cd lessons/18-integer-types/linux/examples && make
```

## Sizes: the LP64 model

Linux and macOS on ARM64 both use **LP64**: `long` and pointers are 64 bits,
`int` is 32.

| C type | Bytes | Range | Register | Load | Store |
|--------|-------|-------|----------|------|-------|
| `char` / `signed char` / `unsigned char` | 1 | -128..127 or 0..255 | `w` | `ldrsb` / `ldrb` | `strb` |
| `short` / `unsigned short` | 2 | -32768..32767 / 0..65535 | `w` | `ldrsh` / `ldrh` | `strh` |
| `int` / `unsigned` | 4 | ±2.1 × 10⁹ / 0..4.3 × 10⁹ | `w` | `ldr w` (or `ldrsw x`) | `str w` |
| `long` / `unsigned long` | 8 | ±9.2 × 10¹⁸ / 0..1.8 × 10¹⁹ | `x` | `ldr x` | `str x` |
| `long long` | 8 | same as `long` | `x` | `ldr x` | `str x` |
| pointer, `size_t` | 8 | 0..2⁶⁴-1 | `x` | `ldr x` | `str x` |
| `bool` (`_Bool`) | 1 | 0 or 1 | `w` | `ldrb` | `strb` |

Whether plain `char` is signed is up to the platform: on Linux AArch64 it is
**unsigned**, on Apple it is **signed** (`examples/char_sign.c` checks). Use
`signed char` or `unsigned char` when it matters.

## The type is in the instruction, not the data

Memory just holds bytes. `examples/loads.s` reads the same eight `0xff` bytes
as six different types:

```asm
    ldrb w1, [x19]              // zero-extend 1 byte: 255
    ldrsb x2, [x19]             // sign-extend 1 byte to 64 bits: -1
    ...
    ldrh w1, [x19]              // zero-extend 2 bytes
    ldrsh x2, [x19]             // sign-extend 2 bytes
    ...
    ldr w1, [x19]               // 4 bytes; writing w1 zeroes the top of x1
    ldrsw x2, [x19]             // 4 bytes, sign-extended
```

```console
# ./loads
unsigned char 255, signed char -1
unsigned short 65535, short -1
unsigned int 4294967295, int -1
```

When a C compiler sees `x = *p` it chooses the load from `p`'s type. In
assembly, you choose: getting it wrong is how a `-1` becomes `255`.

## Casts are truncations and extensions

There are only three things a cast between integer types can do:

| Cast | Operation | Instruction |
|------|-----------|-------------|
| to a **narrower** type | keep the low bits | nothing (use the `w` register), or `and #0xff`/`#0xffff` |
| to a wider type, from **signed** | sign-extend | `sxtb`, `sxth`, `sxtw` |
| to a wider type, from **unsigned** | zero-extend | `uxtb`, `uxth`, or `mov w, w` (writing a `w` clears the top) |

`examples/casts.s`:

```asm
    mov w1, w9                  // (int)big: just use the low 32 bits

    mov w9, #-5                 // int neg = -5 (0xfffffffb in w9)
    sxtw x1, w9                 // (long)neg: copy bit 31 into bits 32-63
    mov w2, w9                  // (long)(unsigned)neg: writing w2 zero-extends

    sxtb w1, w9                 // (char)300 -> 0x2c = 44, then sign-extend for %d
    sxth w2, w9                 // (short)0x18000: low 16 bits 0x8000 = -32768
```

```console
# ./casts
(int)0x123456789 = 0x23456789
(long)-5 = -5, (long)(unsigned)-5 = 4294967291
(char)300 = 44, (short)0x18000 = -32768
```

The rule for extension is about the **source** type: a signed value is
sign-extended, an unsigned one zero-extended, whatever the destination is.

Extension can also be folded into arithmetic and addressing:
`add x0, x1, w2, sxtw` adds a sign-extended `int` to a `long`, and
`ldr x0, [x1, w2, sxtw #3]` indexes a `long` array with an `int`.

## Integer promotion: small types become `int`

C never does arithmetic on anything smaller than `int`. Before `+`, `-`, `*`,
`<`, and so on, `char` and `short` values are **promoted** to `int`. That fits
AArch64 well, since there are no 8- or 16-bit arithmetic instructions anyway.
`examples/promote.s`:

```c
unsigned char a = 200, b = 100;
int           s = a + b;        // 300: computed as int
unsigned char c = a + b;        // 44: 300 truncated back to 8 bits
```

```asm
    add w1, w9, w10             // s = a + b, computed in 32 bits: 300
    and w2, w1, #0xff           // c = (unsigned char)(a + b): keep 8 bits
```

The truncation happens only when the result is **stored** into the small type.

The same thing one size up: `unsigned int` arithmetic wraps at 2³², even if
the result goes into a `long`, unless an operand is converted *first*:

```c
unsigned z = x + y;             // wraps
long     w = (long)x + y;       // computed in 64 bits
```

```asm
    add w1, w9, w10             // z = x + y in 32 bits: wraps
    add x2, x9, x10             // w: the same registers as 64-bit values
```

```console
# ./promote
int s = 300, unsigned char c = 44
unsigned z = 705032704, long w = 5000000000
```

This is the "assigning to a `long` does not help" bug, at the instruction
level: the add width is decided by the operand types, not the destination.

## Mixing signed and unsigned

When an operator mixes types, C converts both to a common type (the "usual
arithmetic conversions"). The surprising rule: **`int` and `unsigned int` meet
as `unsigned int`.** So `-1 < 1u` is *false*: -1 becomes 4294967295.

`examples/mixed_compare.s` shows that this is just a choice of condition code:

```asm
    cmp w9, w10
    cset w1, lt                 // r1: signed condition
    cmp w9, w10
    cset w2, lo                 // r2: unsigned condition (what C chooses here)
```

When one side is wider (`long` vs `unsigned int`), the narrower one is
converted to the wider type instead: zero-extend `u`, then a signed compare.

```console
# ./mixed_compare
signed: 1, mixed int/unsigned: 0, mixed long/unsigned: 1
```

The practical rule: in your own C, do not mix signed and unsigned in
comparisons. In assembly, every compare forces you to decide which you meant.

## The high half of a product: `umulh` and `smulh`

`mul` keeps the low 64 bits of a 128-bit product (lesson 07). The other half
comes from:

| Instruction | Gives |
|-------------|-------|
| `umulh xd, xn, xm` | high 64 bits of the unsigned product |
| `smulh xd, xn, xm` | high 64 bits of the signed product |

```asm
    mov x9, #-1                 // a = b = 2^64 - 1
    umulh x1, x9, x9            // high 64 bits of the unsigned product
    mul x2, x9, x9              // low 64 bits (the same for signed and unsigned)
```

```console
# ./mul128
0xffffffffffffffff * 0xffffffffffffffff = 0xfffffffffffffffe 0000000000000001
-3 * 7 = high -1, low -21
```

For 32-bit values the full product fits in 64 bits: `umull x0, w1, w2` and
`smull x0, w1, w2` multiply two `w` registers into one `x`.

`umulh` is also an overflow check: a 64-bit unsigned multiply overflowed if
and only if the high half is non-zero (exercise 18.7). And compilers use it to
divide by constants (lesson 27).

## 128-bit arithmetic: the carry flag

GCC and Clang support `__int128`. With only 64-bit registers, a 128-bit value
lives in two of them, `hi:lo`. Adding two such values is addition with a carry
between the halves, like adding two-digit numbers by hand:

```asm
    adds x19, x19, #1           // low + 1: wraps to 0 and sets C (carry out)
    adc x20, x20, xzr           // high + 0 + C
```

`adds` sets the carry flag if the low half overflowed; `adc` ("add with
carry") adds it into the high half. Subtraction is the same with `subs` and
`sbc`. On AArch64 the carry flag after a subtraction means "no borrow", which
is exactly what `sbc` expects. `examples/add128.s`:

```console
# ./add128
2^64 - 1 = 0x0000000000000000ffffffffffffffff
+ 1      = 0x00000000000000010000000000000000
- 2      = 0x0000000000000000fffffffffffffffe
```

Chains of `adds`/`adc` extend this to 256 bits or more: this is how big-number
libraries work.

## Overflow: undefined in C, defined in hardware

| | C says | The CPU does |
|-|--------|--------------|
| unsigned overflow | wraps around (defined) | wraps; sets C on `adds` |
| signed overflow | **undefined behaviour** | wraps; sets V on `adds` |

"Undefined" means a C compiler may assume signed overflow never happens and
optimise accordingly (for example, deciding `x + 1 > x` is always true). The
hardware itself is perfectly predictable: two's complement wraps. When you
need to know, use the flag-setting instruction and test the flag.
`examples/overflow.s`:

```asm
    adds w2, w19, #1            // 32-bit add that sets the flags
    cset w3, vs                 // V: signed overflow happened
```

```console
# ./overflow
2147483647 + 1 = -2147483648, overflow = 1
2147483646 + 1 = 2147483647, overflow = 0
```

GCC's `__builtin_add_overflow` compiles to exactly this.

## `bool`

Converting to `bool` is not truncation: any non-zero value becomes 1.

```asm
    cmp x1, #0
    cset w2, ne                 // (bool)x
```

`(bool)256` is 1, while `(unsigned char)256` is 0 (exercise 18.8).

## C to assembly

| C | Assembly |
|---|----------|
| `signed char c = *p;` | `ldrsb w0, [p]` |
| `unsigned char c = *p;` | `ldrb w0, [p]` |
| `long x = *(int *)p;` | `ldrsw x0, [p]` |
| `long x = *(unsigned *)p;` | `ldr w0, [p]` (top half zeroed) |
| `(int)l` | use `w` of the register |
| `(long)i` | `sxtw x0, w0` |
| `(long)u` | `mov w0, w0` (or `uxtw`) |
| `(signed char)i`, `(short)i` | `sxtb w0, w0`, `sxth w0, w0` |
| `(unsigned char)i` | `and w0, w0, #0xff` (or `uxtb`) |
| `a < b`, `int` vs `unsigned` | `cmp w, w` / unsigned condition (`lo`) |
| `l + i` (`long` + `int`) | `add x0, x1, w2, sxtw` |
| `(unsigned __int128)a * b` | `mul` (low) + `umulh` (high) |
| `__int128` add | `adds` (low) + `adc` (high) |
| `__builtin_add_overflow` | `adds` + `cset vs` (signed) or `cset cs` (unsigned) |
| `(bool)x` | `cmp x, #0` / `cset w, ne` |

## Common mistakes

- **Zero-extending a signed value** (or the reverse). `-1` becomes 255, or
  255 becomes -1.
- **Doing `int` arithmetic in `x` registers** without truncating: a result
  that should wrap at 2³² does not.
- **Doing `long` arithmetic in `w` registers**: it wraps when it should not.
- **Forgetting promotion**: `unsigned char` arithmetic does not wrap at 256
  until the result is stored.
- **Signed condition codes on unsigned values** after a mixed comparison.
- **Using `adc` without `adds` before it.** Plain `add` does not set the carry.
- **Assuming plain `char` is signed** (or unsigned). It differs between Linux
  and macOS.

## Recap

- LP64: `char` 1, `short` 2, `int` 4, `long`/pointer 8 bytes.
- The load instruction chooses the type: `ldrb`/`ldrsb`, `ldrh`/`ldrsh`,
  `ldr w`/`ldrsw`, `ldr x`.
- Casts: narrowing keeps the low bits; widening sign-extends signed sources and
  zero-extends unsigned ones.
- Small types are promoted to `int` before arithmetic; truncation happens on
  store.
- `int` and `unsigned` mixed become `unsigned`: the condition code shows it.
- `umulh`/`smulh` give the high half of a product; `adds`/`adc` chain 128-bit
  addition.
- Signed overflow is undefined in C but sets V in hardware; check it with
  `adds` and `vs`.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next.
