// ex6.s - dot product and vector length, using sqrt from libm (lesson 23, exercise 23.6, macOS)
//
// Build: make ex6             (no -lm needed on macOS)
// Run:   ./ex6
// Expected output:
//   dot(a, b) = 32.000000
//   |a| = 3.741657
//   |b| = 8.774964

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16

    adrp x0, vec_a@PAGE
    add x0, x0, vec_a@PAGEOFF
    adrp x1, vec_b@PAGE
    add x1, x1, vec_b@PAGEOFF
    mov x2, #3
    bl dot                      // dot(a, b, 3)
    str d0, [sp]
    adrp x0, f_dot@PAGE
    add x0, x0, f_dot@PAGEOFF
    bl _printf

    adrp x0, vec_a@PAGE
    add x0, x0, vec_a@PAGEOFF
    mov x1, #3
    bl length
    str d0, [sp]
    adrp x0, f_la@PAGE
    add x0, x0, f_la@PAGEOFF
    bl _printf

    adrp x0, vec_b@PAGE
    add x0, x0, vec_b@PAGEOFF
    mov x1, #3
    bl length
    str d0, [sp]
    adrp x0, f_lb@PAGE
    add x0, x0, f_lb@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #16
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
    bl _sqrt                    // the C library's sqrt
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__const
    .p2align 3
vec_a: .double 1.0, 2.0, 3.0
vec_b: .double 4.0, 5.0, 6.0

    .section __TEXT,__cstring
f_dot: .asciz "dot(a, b) = %f\n"
f_la:  .asciz "|a| = %f\n"
f_lb:  .asciz "|b| = %f\n"
