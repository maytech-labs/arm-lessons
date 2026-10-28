// ex7.s - Exercise 18.7: detect overflow in an unsigned 64-bit multiply.
//
// C:      int mul_overflows(unsigned long a, unsigned long b) {
//             unsigned long r;  return __builtin_mul_overflow(a, b, &r);
//         }
//
// Build:  make
// Run:    ./ex7
// Expected output:
//   4294967296 * 4294967295: fits
//   4294967296 * 4294967296: overflow

    .global main

    .section .rodata
fmt:    .asciz "%lu * %lu: %s\n"
fits:   .asciz "fits"
over:   .asciz "overflow"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x1, #0x100000000        // 2^32
    mov x2, #0xffffffff         // 2^32 - 1
    bl report
    mov x1, #0x100000000
    mov x2, #0x100000000
    bl report

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// void report(unsigned long a (x1), unsigned long b (x2)): prints the line
report:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    umulh x9, x1, x2            // the high 64 bits of the true product
    adrp x3, fits
    add x3, x3, :lo12:fits
    adrp x10, over
    add x10, x10, :lo12:over
    cmp x9, #0
    csel x3, x10, x3, ne        // non-zero high half: it did not fit
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    ldp x29, x30, [sp], #16
    ret
