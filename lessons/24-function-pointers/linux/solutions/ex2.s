// ex2.s - twice(f, x) calls f(f(x)) (lesson 24, exercise 24.2)
//
// Build: make ex2
// Run:   ./ex2
// Expected output:
//   twice(add3, 10) = 16
//   twice(square, 3) = 81
//
// The C version:
//   int add3(int x)   { return x + 3; }
//   int square(int x) { return x * x; }
//   int twice(int (*f)(int), int x) { return f(f(x)); }

    .text
    .global main
    .p2align 2

add3:
    add w0, w0, #3
    ret

square:
    mul w0, w0, w0
    ret

// int twice(int (*f)(int), int x)
twice:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                     // keep f: the first call may trash x0-x17
    mov w0, w1                      // f(x)
    blr x19
    blr x19                         // f(result): result is already in w0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adr  x0, add3
    mov  w1, #10
    bl   twice
    mov  w1, w0
    adrp x0, fmt_add3
    add  x0, x0, :lo12:fmt_add3
    bl   printf

    adr  x0, square
    mov  w1, #3
    bl   twice
    mov  w1, w0
    adrp x0, fmt_square
    add  x0, x0, :lo12:fmt_square
    bl   printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
fmt_add3:   .asciz "twice(add3, 10) = %d\n"
fmt_square: .asciz "twice(square, 3) = %d\n"
