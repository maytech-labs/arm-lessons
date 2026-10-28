// math_lib.s - call sqrt, pow and floor from the C math library (lesson 23)
//
// Build: make math_lib        (the Makefile adds -lm for this program)
// Run:   ./math_lib
// Expected output:
//   sqrt(2)      = 1.414214
//   pow(2, 10)   = 1024.000000
//   pow(2, 0.5)  = 1.414214
//   floor(-2.5)  = -3.000000

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    fmov d0, #2.0               // sqrt(2.0)
    bl sqrt                     // result in d0
    adrp x0, f_sqrt
    add x0, x0, :lo12:f_sqrt
    bl printf

    fmov d0, #2.0               // pow(2.0, 10.0): two double arguments
    fmov d1, #10.0
    bl pow
    adrp x0, f_pow
    add x0, x0, :lo12:f_pow
    bl printf

    fmov d0, #2.0               // pow(2.0, 0.5)
    fmov d1, #0.5
    bl pow
    adrp x0, f_pow2
    add x0, x0, :lo12:f_pow2
    bl printf

    fmov d0, #-2.5              // floor(-2.5): rounds down, not toward zero
    bl floor
    adrp x0, f_floor
    add x0, x0, :lo12:f_floor
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
f_sqrt:  .asciz "sqrt(2)      = %f\n"
f_pow:   .asciz "pow(2, 10)   = %f\n"
f_pow2:  .asciz "pow(2, 0.5)  = %f\n"
f_floor: .asciz "floor(-2.5)  = %f\n"
