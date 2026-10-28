// ex4.s - Exercise 20.4: main file using the stack module in stack.s (macOS).
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   size 3, popped 30 20 10, size 0

    .global _main

    .section __TEXT,__const
fmt:    .asciz "size %ld, popped %ld %ld %ld, size %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov x0, #10
    bl stack_push
    mov x0, #20
    bl stack_push
    mov x0, #30
    bl stack_push
    bl stack_size
    mov x19, x0
    bl stack_pop
    mov x20, x0
    bl stack_pop
    mov x21, x0
    bl stack_pop
    mov x22, x0
    bl stack_size
    mov x5, x0
    mov x1, x19
    mov x2, x20
    mov x3, x21
    mov x4, x22
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #48             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    str x4, [sp, #24]
    str x5, [sp, #32]
    bl _printf
    add sp, sp, #48

    mov w0, #0
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
