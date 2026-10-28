// ex9.s - approximate pi by integrating 4 / (1 + x^2) from 0 to 1 (lesson 23, exercise 23.9, macOS)
//
// Build: make ex9
// Run:   ./ex9
// Expected output:
//   pi ~ 3.1415927369 with n = 1000
//   error = 8.33e-08

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]
    sub sp, sp, #16             // two variadic arguments

    mov x0, #1000
    bl integrate_pi             // d0 = integrate_pi(1000)
    fmov d8, d0
    str d0, [sp]                // printf(f_pi, pi, n): pi first, then n
    mov x1, #1000
    str x1, [sp, #8]
    adrp x0, f_pi@PAGE
    add x0, x0, f_pi@PAGEOFF
    bl _printf

    adrp x0, k_pi@PAGE
    ldr d1, [x0, k_pi@PAGEOFF]
    fsub d0, d8, d1             // estimate - true pi
    str d0, [sp]
    adrp x0, f_err@PAGE
    add x0, x0, f_err@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #16
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// double integrate_pi(long n)     midpoint rule     (leaf)
//     double h = 1.0 / n, sum = 0;
//     for (long i = 0; i < n; i++) { double x = (i + 0.5) * h; sum += 4 / (1 + x*x); }
//     return sum * h;
integrate_pi:
    scvtf d1, x0
    fmov d2, #1.0
    fdiv d1, d2, d1             // h = 1.0 / n
    fmov d0, xzr                // sum = 0
    fmov d3, #0.5
    fmov d4, #4.0
    mov x1, #0                  // i = 0
pi_loop:
    cmp x1, x0
    b.ge pi_done
    scvtf d5, x1
    fadd d5, d5, d3             // i + 0.5
    fmul d5, d5, d1             // x = (i + 0.5) * h
    fmadd d5, d5, d5, d2        // 1 + x*x
    fdiv d5, d4, d5             // 4 / (1 + x*x)
    fadd d0, d0, d5             // sum += ...
    add x1, x1, #1
    b pi_loop
pi_done:
    fmul d0, d0, d1             // sum * h
    ret

    .section __TEXT,__const
    .p2align 3
k_pi:  .double 3.141592653589793

    .section __TEXT,__cstring
f_pi:  .asciz "pi ~ %.10f with n = %ld\n"
f_err: .asciz "error = %.2e\n"
