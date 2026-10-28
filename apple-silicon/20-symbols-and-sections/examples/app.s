// app.s - the main file of a two-file program (with mathlib.s) (macOS).
//
// mathlib.s exports square, cube, and the variable mathlib_calls; its helper
// mul3 is not exported (no .global), so this file cannot call it.
//
// Build:  make             (assembles both files and links them together)
// Run:    ./app
// Look:   nm app.o mathlib.o    after:  make app.o mathlib.o
// Expected output:
//   square(7) = 49, cube(3) = 27, calls = 2

    .global _main

    .section __TEXT,__const
fmt:    .asciz "square(7) = %ld, cube(3) = %ld, calls = %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov x0, #7
    bl square                   // defined in another file: the linker connects it
    mov x19, x0
    mov x0, #3
    bl cube
    mov x2, x0
    mov x1, x19
    adrp x9, mathlib_calls@PAGE // a variable defined in mathlib.s
    add x9, x9, mathlib_calls@PAGEOFF
    ldr x3, [x9]
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
