// ex6.s - Exercise 18.6: sum an array of signed chars into a long (macOS).
//
// C:      signed char a[] = {-1, -2, 100, -128, 27};
//         long sum = 0;  for (...) sum += a[i];
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   with ldrsb: -4, with ldrb: 764

    .global _main

    .data
a:  .byte -1, -2, 100, -128, 27
    .equ N, . - a

    .section __TEXT,__const
fmt:    .asciz "with ldrsb: %ld, with ldrb: %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF
    mov x10, #N
    mov x1, #0                  // correct sum
    mov x2, #0                  // wrong sum, for comparison
loop:
    ldrsb x11, [x9]             // sign-extend: -1 stays -1
    add x1, x1, x11
    ldrb w12, [x9], #1          // zero-extend: -1 becomes 255
    add x2, x2, x12
    subs x10, x10, #1
    b.ne loop

    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
