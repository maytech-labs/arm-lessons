// macros.s - .macro, .include, .rept and .set (macOS).
//
// The macros come from macros.inc. .rept with a .set counter makes the
// assembler generate a table of squares, so no code computes them.
//
// Build:  make
// Run:    ./macros
// Expected output:
//   squares: 0 1 4 9 16 25 36 49 64 81

    .include "macros.inc"

    .global _main

    .data
    .p2align 3
squares:
    .set i, 0
    .rept 10                    // the next lines, ten times...
    .quad i * i                 // ...with i = 0, 1, 2, ... 9
    .set i, i + 1
    .endr
    .equ N, (. - squares) / 8

    .section __TEXT,__const
head:   .asciz "squares:"
item:   .asciz " %ld"
nl:     .asciz "\n"

    .text
    .p2align 2
_main:
    PROLOGUE
    stp x19, x20, [sp, #-16]!
    LOAD_ADDR x0, head
    bl _printf
    LOAD_ADDR x19, squares
    mov x20, #N
1:  ldr x1, [x19], #8
    LOAD_ADDR x0, item
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    bl _printf
    add sp, sp, #16
    subs x20, x20, #1
    b.ne 1b
    LOAD_ADDR x0, nl
    bl _printf
    ldp x19, x20, [sp], #16
    mov w0, #0
    EPILOGUE
