# Lesson 11 solutions: written answers

Programs for 11.4 to 11.10 are the `exN.s` files in this directory.

## Exercise 11.1

The bytes are `9c ff 01 80` (lowest address first), so as a 2-byte number they
are `0xff9c` and as a 4-byte number `0x8001ff9c` (little-endian).

| Instruction | `x1` |
|-------------|------|
| `ldrb w1, [x0]` | `0x000000000000009c` |
| `ldrsb x1, [x0]` | `0xffffffffffffff9c` (top bit of `0x9c` is 1) |
| `ldrh w1, [x0]` | `0x000000000000ff9c` |
| `ldrsh x1, [x0]` | `0xffffffffffffff9c` (top bit of `0xff9c` is 1) |
| `ldr w1, [x0]` | `0x000000008001ff9c` |
| `ldrsw x1, [x0]` | `0xffffffff8001ff9c` (top bit of `0x8001ff9c` is 1) |
| `ldrsb w1, [x0, #3]` | `0x00000000ffffff80`: sign-extended to 32 bits only, then writing `w1` zeroes the upper half |

## Exercise 11.2

| Instruction | Address accessed | `x0` afterwards |
|-------------|------------------|-----------------|
| `ldr x1, [x0]` | `0x1000` | `0x1000` |
| `ldr x1, [x0, #16]` | `0x1010` | `0x1000` |
| `ldr x1, [x0, x9, lsl #3]` | `0x1000 + 24 = 0x1018` | `0x1000` |
| `ldr w1, [x0, x9, lsl #2]` | `0x1000 + 12 = 0x100c` | `0x1000` |
| `ldr x1, [x0, #16]!` | `0x1010` | `0x1010` |
| `ldr x1, [x0], #16` | `0x1000` | `0x1010` |
| `strb w1, [x0, #-1]!` | `0x0fff` | `0x0fff` |
| `ldp x1, x2, [x0], #16` | `x1` from `0x1000`, `x2` from `0x1008` | `0x1010` |

## Exercise 11.3

1. `a` = `0x2000`, `b` = `0x2001`, `c` = `0x2008`, `d` = `0x2010`.
2. Bytes:

   ```
   0x2000: 41                       a
   0x2001: be ba fe ca              b (little-endian 0xcafebabe)
   0x2005: 00 00 00                 padding from .p2align 3
   0x2008: 01 00 00 00 00 00 00 00  c
   0x2010: 34 12                    d
   ```

   18 bytes in total.
3. No: `b` is a 4-byte value at `0x2001`, which is not a multiple of 4. Order
   the values from largest to smallest and nothing needs padding:

   ```asm
       .data
       .p2align 3
   c:  .quad 1                 // 0x2000
   b:  .word 0xcafebabe        // 0x2008
   d:  .hword 0x1234           // 0x200c
   a:  .byte 0x41              // 0x200e
   ```

   15 bytes, every value naturally aligned.
