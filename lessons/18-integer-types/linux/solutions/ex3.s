// ex3.s - Exercise 18.3: average of two unsigned ints without overflow.
//
// C:      unsigned avg(unsigned a, unsigned b) { return (a & b) + ((a ^ b) >> 1); }
//         // (a + b) / 2 would overflow 32 bits for large a and b
//
// Build:  make
// Run:    ./ex3
// Expected output:
//   naive 1852516353, safe 4000000001

    .global main

    .section .rodata
fmt:    .asciz "naive %u, safe %u\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    movz w9, #0x2800            // a = 4000000000 = 0xee6b2800
    movk w9, #0xee6b, lsl #16
    add w10, w9, #2             // b = 4000000002

    add w1, w9, w10             // naive: a + b wraps in 32 bits...
    lsr w1, w1, #1              // ...so the "average" is wrong

    and w11, w9, w10            // bits both have: counted fully
    eor w12, w9, w10            // bits only one has: counted half
    add w2, w11, w12, lsr #1    // safe average
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
