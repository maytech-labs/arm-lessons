// ex5.s - Exercise 20.5: a table built by .rept, printed with a macro (macOS).
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   cubes: 0 1 8 27 64 125 216 343

    .global _main

    // PRINTF1 fmt, reg: printf(fmt, reg), keeping the address loading tidy
    .macro PRINTF1 fmt, reg
    mov x1, \reg
    adrp x0, \fmt@PAGE
    add x0, x0, \fmt@PAGEOFF
    sub sp, sp, #16             // macOS: the one variadic argument goes on the stack
    str x1, [sp]
    bl _printf
    add sp, sp, #16
    .endm

    .data
    .p2align 3
cubes:
    .set i, 0
    .rept 8
    .quad i * i * i
    .set i, i + 1
    .endr
    .equ N, (. - cubes) / 8

    .section __TEXT,__const
head:   .asciz "cubes:"
item:   .asciz " %ld"
nl:     .asciz "\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    PRINTF1 head, xzr
    adrp x19, cubes@PAGE
    add x19, x19, cubes@PAGEOFF
    mov x20, #N
1:  ldr x9, [x19], #8
    PRINTF1 item, x9
    subs x20, x20, #1
    b.ne 1b
    PRINTF1 nl, xzr
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
