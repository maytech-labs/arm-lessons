# Lesson 07: Arithmetic

## Goals

After this lesson you can:

- Add, subtract, negate, multiply, and divide with registers and constants.
- Compute a remainder (C's `%`).
- Use multiply-add (`madd`) and multiply-subtract (`msub`).
- Know which constants fit directly into an instruction and build any 64-bit
  constant with `movz` and `movk`.
- Choose between `w` (32-bit, C `int`) and `x` (64-bit, C `long`) registers,
  and predict when results wrap around.
- Choose between signed (`sdiv`) and unsigned (`udiv`) division.

## Before you start

You need lessons 02 (two's complement, wraparound), 04 (`mov`, exit status),
and 06 (the debugger). Results in this lesson come back as the exit status,
so they must fit in 0-255; anything bigger, check in the debugger. Printing
numbers arrives in lesson 11.

```console
# cd lessons/07-arithmetic/linux/examples && make
```

## The shape of an arithmetic instruction

Almost every arithmetic instruction has three operands:

```asm
    add x0, x1, x2              // x0 = x1 + x2
```

Destination first, then two sources, like `x0 = x1 + x2` in C. The sources are
not changed. The destination may be the same as a source:
`add x0, x0, #1` is `x0 = x0 + 1`, which is C's `x0++`.

## `add` and `sub`

`examples/add.s`:

```c
long a = 20, b = 22;
return a + b;
```

```asm
    mov x1, #20                 // a = 20
    mov x2, #22                 // b = 22
    add x0, x1, x2              // x0 = a + b = 42 (register + register)
    add x0, x0, #0              // x0 = x0 + 0 (register + immediate; no change)
```

The second source may be a register or an immediate. `sub` works the same way:

```asm
    sub x3, x1, x2              // x3 = x1 - x2
    sub x0, x0, #16             // x0 = x0 - 16
```

**Predict:** what is the exit status of `examples/sub.s`?

```asm
    mov x1, #10                 // a = 10
    mov x2, #13                 // b = 13
    sub x3, x1, x2              // d = a - b = -3 = 0xfffffffffffffffd
    neg x4, x3                  // x4 = -d = 3
    neg x0, x4                  // x0 = -3 again
```

```console
# ./sub; echo $?
253
```

10 - 13 is -3. In two's complement (lesson 02) that is
`0xfffffffffffffffd`. The shell keeps the low byte, `0xfd`, which is 253.
The CPU did not do anything special for a negative result: subtraction is
just binary subtraction, and the bits come out as two's complement on their
own.

`neg x4, x3` is `x4 = -x3`. (It is really `sub x4, xzr, x3`: zero minus x3.)

## Multiplication: `mul`, `madd`, `msub`

```asm
    mul x3, x1, x2              // x3 = x1 * x2
```

Unlike `add`, **`mul` has no immediate form**. To multiply by 9, first put 9 in
a register. `examples/fahrenheit.s` converts 100 °C:

```c
long c = 100;
long f = c * 9 / 5 + 32;
```

```asm
    mov x1, #100                // c = 100
    mov x2, #9                  // mul has no immediate form: put 9 in a register
    mul x0, x1, x2              // x0 = c * 9 = 900
    mov x2, #5                  // divisor 5, also in a register
    sdiv x0, x0, x2             // x0 = 900 / 5 = 180
    add x0, x0, #32             // x0 = 180 + 32 = 212
```

AArch64 has two fused forms that are very common:

| Instruction | Meaning |
|-------------|---------|
| `madd xd, xn, xm, xa` | `xd = xa + xn * xm` (multiply-add) |
| `msub xd, xn, xm, xa` | `xd = xa - xn * xm` (multiply-subtract) |

The fourth register is the one added to or subtracted from. In fact `mul` is
just `madd` with `xzr` as the fourth operand. `examples/multiply.s` uses all
three; step through it in the debugger and check each register.

A 64-bit multiply keeps only the low 64 bits of the product. If the true
product is bigger, the top bits are lost silently: that is overflow, and the
CPU does not warn you. (Getting the high half is lesson 18.)

## Division: `udiv` and `sdiv`

```asm
    udiv x3, x1, x2             // x3 = x1 / x2, treating both as unsigned
    sdiv x3, x1, x2             // x3 = x1 / x2, treating both as signed
```

Both round **toward zero**, like C: 7 / 2 = 3 and -7 / 2 = -3.

Division needs both operands in registers. There is no immediate form.

### Why two divisions?

Addition, subtraction, and (the low 64 bits of) multiplication give the same
bits whether you think of the numbers as signed or unsigned. Division does
not. `examples/signed_div.s`:

```asm
    mov x1, #-7                 // a = -7 (0xfffffffffffffff9)
    mov x2, #2                  // b = 2
    sdiv x3, x1, x2             // q = -7 / 2 = -3 (signed division)
    msub x4, x3, x2, x1         // r = a - q * b = -7 - (-6) = -1
    udiv x5, x1, x2             // the same bits divided as UNSIGNED: 0x7ffffffffffffffc
```

As a signed number `0xfffffffffffffff9` is -7, and -7 / 2 is -3. As an
unsigned number the same bits are 18446744073709551609, and half of that is a
huge number. **You** decide which is meant, by choosing the instruction. In C
the compiler decides for you based on the variable's type: `long` gets `sdiv`,
`unsigned long` gets `udiv`.

### Remainder: there is no `mod` instruction

C's `a % b` is the part left over: `a - (a / b) * b`. That is one division and
one `msub`. `examples/divide.s`:

```asm
    mov x1, #100                // a = 100
    mov x2, #7                  // b = 7
    udiv x3, x1, x2             // q = a / b = 14 (rounds toward zero)
    msub x4, x3, x2, x1         // r = a - q * b = 100 - 98 = 2
```

Learn this pair by heart: **divide, then `msub`**. It works for signed
numbers too (use `sdiv`): the remainder then has the same sign as `a`,
exactly like C. In `signed_div.s`, -7 % 2 is -1.

### Dividing by zero

```asm
    mov x1, #42
    mov x2, #0
    udiv x0, x1, x2             // x0 = 42 / 0 = 0 on AArch64 (no trap, no signal)
```

On many CPUs, dividing by zero crashes the program. On AArch64 it does not:
the result is simply 0 (`examples/divzero.s` exits with 0). In C, dividing by
zero is undefined behaviour, so a C program must never do it anyway; in
assembly, you must check the divisor yourself (lesson 09) if zero is possible.

## Which constants fit?

Every instruction is 32 bits, and some of those bits name the operation and
registers. So an immediate can only be a few bits wide. The rules differ by
instruction:

| Instruction | Immediate allowed |
|-------------|-------------------|
| `add`, `sub` | 0-4095, or 0-4095 shifted left by 12 (multiples of 4096 up to 16773120) |
| `mov` | any 16-bit value at bit 0, 16, 32, or 48; its bitwise inverse; or certain repeating bit patterns |
| `mul`, `madd`, `msub`, `udiv`, `sdiv` | none: registers only |

Examples:

```asm
    add x0, x0, #4095           // OK
    add x0, x0, #4096           // OK: 1 shifted left by 12
    add x0, x0, #4097           // error: immediate out of range
    mov x0, #65535              // OK: 0xffff
    mov x0, #65536              // OK: 0x1 in the second 16-bit chunk
    mov x0, #65537              // error: 0x10001 needs two chunks
    mov x0, #-1                 // OK: the inverse of 0
    mul x0, x1, #3              // error: mul takes registers only
```

`mov` with an immediate is not one instruction but a family; the assembler
picks whichever encoding fits. When nothing fits, it reports an error. You
do not need to memorise the exact rules: try it, and if the assembler
complains, build the value in steps.

The assembler also helps where it can: `sub x0, x0, #-1` is quietly assembled
as `add x0, x0, #1`.

### Building any 64-bit constant: `movz` and `movk`

A 64-bit value is four 16-bit chunks. Load them one at a time.
`examples/bigconst.s`:

```asm
    movz x0, #0x7788            // x0 = 0x0000000000007788 (other bits zeroed)
    movk x0, #0x5566, lsl #16   // x0 = 0x0000000055667788 (bits 16-31 replaced)
    movk x0, #0x3344, lsl #32   // x0 = 0x0000334455667788 (bits 32-47 replaced)
    movk x0, #0x1122, lsl #48   // x0 = 0x1122334455667788 (bits 48-63 replaced)
```

- **`movz`** (move, zeroing) puts a 16-bit value at a chosen position and sets
  every other bit to 0.
- **`movk`** (move, keeping) puts a 16-bit value at a chosen position and
  **keeps** the other bits.
- `lsl #16` means "at bit position 16". Positions are 0, 16, 32, or 48.

Always start with `movz`, then `movk` the rest. Chunks that are zero can be
skipped, since `movz` already cleared them. Step through it in the debugger
with `display/x $x0` to watch the value fill in.

### `ldr x0, =value`

```asm
    ldr x0, =0x1122334455667788
```

This is a **pseudo-instruction**: the assembler stores the 8-byte value in
memory near your code and generates a *load* from there (`examples/ldrconst.s`).
It is convenient, but it is a memory access, which is lesson 11. This course
uses `movz`/`movk` so you can see exactly what happens.

## 32-bit and 64-bit: `w` and `x`

Every instruction in this lesson also works on `w` registers, doing 32-bit
arithmetic:

```asm
    add w0, w1, w2              // 32-bit add; the top half of x0 becomes 0
```

That matters because C's `int` is 32 bits and `long` is 64 bits (on Linux and
macOS on ARM64). An `int` calculation uses `w` registers and wraps at 2^32; a
`long` calculation uses `x` registers and wraps at 2^64. `examples/wrap.s`:

```c
unsigned int  a = 0xffffffff;  a = a + 1;   // wraps to 0
unsigned long b = 0xffffffff;  b = b + 1;   // 0x100000000
```

```asm
    mov w0, #0xffffffff         // a = 0xffffffff (the largest 32-bit value)
    add w0, w0, #1              // a + 1 wraps to 0 in 32 bits
    mov x1, #0xffffffff         // b = 0xffffffff in a 64-bit register
    add x1, x1, #1              // b + 1 = 0x100000000: there is room for the carry
```

The same `add`, different width, different answer. **Choose the register
width that matches the C type.** Lesson 18 covers mixing types and casts.

Do not mix widths in one instruction: `add x0, w1, w2` is an error.

## Putting it together

Converting the C expression `(a + b) * c - d` into instructions follows a
simple recipe:

1. Pick a register for each variable.
2. Compute innermost first, using spare registers for intermediate results.
3. Put constants that an instruction cannot take as immediates into registers.

```asm
    add x5, x1, x2              // t = a + b
    mul x5, x5, x3              // t = t * c
    sub x0, x5, x4              // result = t - d
```

This is exactly what a compiler does, and from lesson 16 on you can compare
your version with its.

## C to assembly

| C (`long` variables) | Assembly |
|----------------------|----------|
| `a = b + c;` | `add xa, xb, xc` |
| `a = b + 10;` | `add xa, xb, #10` |
| `a++;` | `add xa, xa, #1` |
| `a = b - c;` | `sub xa, xb, xc` |
| `a = -b;` | `neg xa, xb` |
| `a = b * c;` | `mul xa, xb, xc` |
| `a = d + b * c;` | `madd xa, xb, xc, xd` |
| `a = d - b * c;` | `msub xa, xb, xc, xd` |
| `a = b / c;` (signed) | `sdiv xa, xb, xc` |
| `a = b / c;` (unsigned) | `udiv xa, xb, xc` |
| `a = b % c;` | `sdiv xt, xb, xc` then `msub xa, xt, xc, xb` |
| `int` instead of `long` | the same, with `w` registers |
| `a = 0x1122334455667788;` | `movz` + three `movk` |

## Common mistakes

- **Immediate on `mul` or `div`.** `mul x0, x1, #3` is an error; load 3 into a
  register first.
- **Immediate out of range.** `add x0, x0, #5000` fails; use `mov` into a
  register then a register `add`, or split it (`#4096` then `#904`).
- **`movk` without `movz` first.** `movk` keeps the other bits, so whatever
  garbage was in the register stays there.
- **Wrong operand order in `msub`.** `msub xd, xn, xm, xa` is `xa - xn*xm`. The
  value being subtracted *from* is last.
- **`udiv` on a negative number.** You get a huge positive result. Signed
  values need `sdiv`.
- **Mixing `w` and `x` in one instruction.** An error. Pick one width.
- **Expecting overflow to be reported.** It is not. Results wrap silently.
- **Expecting a crash on divide by zero.** You get 0. Check the divisor
  yourself.

## Recap

- `add`/`sub` take a register or a small immediate (0-4095, optionally shifted
  by 12) as the second source.
- `mul`, `madd`, `msub`, `udiv`, `sdiv` take registers only.
- Remainder = divide, then `msub`: `r = a - (a / b) * b`.
- Signed and unsigned division are different instructions; the bits do not say
  which is meant, you do.
- Division by zero gives 0, without a crash.
- Build large constants with `movz` then `movk`, 16 bits at a time.
- `w` registers do 32-bit arithmetic (C `int`), `x` registers 64-bit (C
  `long`). Results wrap at the register width.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next.
