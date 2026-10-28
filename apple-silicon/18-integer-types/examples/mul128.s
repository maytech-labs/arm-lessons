// mul128.s - the full 128-bit product of two 64-bit numbers (macOS).
//
// C:      unsigned __int128 p = (unsigned __int128)a * b;
//         hi = p >> 64;  lo = (unsigned long)p;
//
// Build:  make
// Run:    ./mul128
// Expected output:
//   0xffffffffffffffff * 0xffffffffffffffff = 0xfffffffffffffffe 0000000000000001
//   -3 * 7 = high -1, low -21

    .global _main

    .section __TEXT,__const
fmt1:   .asciz "0xffffffffffffffff * 0xffffffffffffffff = 0x%016lx %016lx\n"
fmt2:   .asciz "-3 * 7 = high %ld, low %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x9, #-1                 // a = b = 2^64 - 1
    umulh x1, x9, x9            // high 64 bits of the unsigned product
    mul x2, x9, x9              // low 64 bits (the same for signed and unsigned)
    adrp x0, fmt1@PAGE
    add x0, x0, fmt1@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov x9, #-3
    mov x10, #7
    smulh x1, x9, x10           // high 64 bits of the SIGNED product: all ones
    mul x2, x9, x10             // low 64 bits: -21
    adrp x0, fmt2@PAGE
    add x0, x0, fmt2@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
