// ex6.s - dot product and vector length, using sqrt from libm (lesson 23, exercise 23.6)
//
// Build: make ex6             (the Makefile adds -lm)
// Run:   ./ex6
// Expected output:
//   dot(a, b) = 32.000000
//   |a| = 3.741657
//   |b| = 8.774964

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, vec_a
    add x0, x0, :lo12:vec_a
    adrp x1, vec_b
    add x1, x1, :lo12:vec_b
    mov x2, #3
    bl dot                      // dot(a, b, 3)
    adrp x0, f_dot
    add x0, x0, :lo12:f_dot
    bl printf

    adrp x0, vec_a
    add x0, x0, :lo12:vec_a
    mov x1, #3
    bl length
    adrp x0, f_la
    add x0, x0, :lo12:f_la
    bl printf

    adrp x0, vec_b
    add x0, x0, :lo12:vec_b
    mov x1, #3
    bl length
    adrp x0, f_lb
    add x0, x0, :lo12:f_lb
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// double dot(const double *a, const double *b, long n)     (leaf)
dot:
    fmov d0, xzr
dot_loop:
    cbz x2, dot_done
    ldr d1, [x0], #8
    ldr d2, [x1], #8
    fmadd d0, d1, d2, d0        // sum += a[i] * b[i]
    sub x2, x2, #1
    b dot_loop
dot_done:
    ret

// double length(const double *v, long n) = sqrt(dot(v, v, n))
length:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x2, x1                  // n
    mov x1, x0                  // b = v
    bl dot                      // a = v already in x0
    bl sqrt                     // the C library's sqrt (needs -lm on Linux)
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
    .p2align 3
vec_a: .double 1.0, 2.0, 3.0
vec_b: .double 4.0, 5.0, 6.0
f_dot: .asciz "dot(a, b) = %f\n"
f_la:  .asciz "|a| = %f\n"
f_lb:  .asciz "|b| = %f\n"
