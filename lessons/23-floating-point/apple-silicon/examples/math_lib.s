// math_lib.s - call sqrt, pow and floor from the C math library (lesson 23, macOS)
//
// Build: make math_lib        (no -lm needed: libm is part of libSystem)
// Run:   ./math_lib
// Expected output:
//   sqrt(2)      = 1.414214
//   pow(2, 10)   = 1024.000000
//   pow(2, 0.5)  = 1.414214
//   floor(-2.5)  = -3.000000

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16             // room for printf's one variadic argument

    fmov d0, #2.0               // sqrt(2.0): not variadic, so d0 as usual
    bl _sqrt                    // result in d0
    str d0, [sp]
    adrp x0, f_sqrt@PAGE
    add x0, x0, f_sqrt@PAGEOFF
    bl _printf

    fmov d0, #2.0               // pow(2.0, 10.0): two double arguments
    fmov d1, #10.0
    bl _pow
    str d0, [sp]
    adrp x0, f_pow@PAGE
    add x0, x0, f_pow@PAGEOFF
    bl _printf

    fmov d0, #2.0               // pow(2.0, 0.5)
    fmov d1, #0.5
    bl _pow
    str d0, [sp]
    adrp x0, f_pow2@PAGE
    add x0, x0, f_pow2@PAGEOFF
    bl _printf

    fmov d0, #-2.5              // floor(-2.5): rounds down, not toward zero
    bl _floor
    str d0, [sp]
    adrp x0, f_floor@PAGE
    add x0, x0, f_floor@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
f_sqrt:  .asciz "sqrt(2)      = %f\n"
f_pow:   .asciz "pow(2, 10)   = %f\n"
f_pow2:  .asciz "pow(2, 0.5)  = %f\n"
f_floor: .asciz "floor(-2.5)  = %f\n"
