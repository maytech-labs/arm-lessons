// ex8.s - Exercise 18.8: bool conversion is not truncation.
//
// C:      (bool)x is x != 0;  (unsigned char)x keeps the low 8 bits.
//         for x in 0, 1, 256, -1: print (bool)x and (unsigned char)x
//
// Build:  make
// Run:    ./ex8
// Expected output:
//   x = 0: bool 0, unsigned char 0
//   x = 1: bool 1, unsigned char 1
//   x = 256: bool 1, unsigned char 0
//   x = -1: bool 1, unsigned char 255

    .global main

    .data
values: .quad 0, 1, 256, -1
    .equ N, (. - values) / 8

    .section .rodata
fmt:    .asciz "x = %ld: bool %d, unsigned char %d\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    adrp x19, values
    add x19, x19, :lo12:values
    mov x20, #N
loop:
    ldr x1, [x19], #8
    cmp x1, #0
    cset w2, ne                 // (bool)x
    and w3, w1, #0xff           // (unsigned char)x
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    subs x20, x20, #1
    b.ne loop

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
