// ex6.s - Exercise 18.6: sum an array of signed chars into a long.
//
// C:      signed char a[] = {-1, -2, 100, -128, 27};
//         long sum = 0;  for (...) sum += a[i];
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   with ldrsb: -4, with ldrb: 764

    .global main

    .data
a:  .byte -1, -2, 100, -128, 27
    .equ N, . - a

    .section .rodata
fmt:    .asciz "with ldrsb: %ld, with ldrb: %ld\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, a
    add x9, x9, :lo12:a
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

    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
