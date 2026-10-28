// ex4.s - evaluate p(x) = 3x^2 - 2x + 1 with Horner's rule and fmadd (lesson 23, exercise 23.4, macOS)
//
// Build: make ex4
// Run:   ./ex4
// Expected output:
//   p(-1.0) = 6.000000
//   p(0.0) = 1.000000
//   p(1.0) = 2.000000
//   p(2.5) = 14.750000

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    sub sp, sp, #16             // two variadic arguments

    adrp x19, xs@PAGE
    add x19, x19, xs@PAGEOFF    // x19 = &xs[0]
    mov x20, #0                 // i = 0
loop:
    cmp x20, #4
    b.ge done
    ldr d0, [x19, x20, lsl #3]  // xs[i]
    bl poly                     // d0 = p(xs[i])
    str d0, [sp, #8]            // 2nd variadic: p(x)
    ldr d0, [x19, x20, lsl #3]
    str d0, [sp]                // 1st variadic: x
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    bl _printf
    add x20, x20, #1
    b loop
done:
    mov w0, #0
    add sp, sp, #16
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// double poly(double x) = (3 * x - 2) * x + 1      (leaf)
poly:
    fmov d1, #3.0
    fmov d2, #-2.0
    fmadd d1, d1, d0, d2        // 3 * x + (-2)
    fmov d2, #1.0
    fmadd d0, d1, d0, d2        // (3x - 2) * x + 1
    ret

    .section __TEXT,__const
    .p2align 3
xs:  .double -1.0, 0.0, 1.0, 2.5

    .section __TEXT,__cstring
fmt: .asciz "p(%.1f) = %f\n"
