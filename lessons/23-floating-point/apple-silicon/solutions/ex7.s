// ex7.s - add 0.1 ten times as float and as double, compare with 1.0 (lesson 23, exercise 23.7, macOS)
//
// Build: make ex7
// Run:   ./ex7
// Expected output:
//   float  sum = 1.00000011920928955
//   double sum = 0.99999999999999989
//   double sum == 1.0: 0
//   fabs(double sum - 1.0) < 1e-9: 1

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]
    sub sp, sp, #16

    // float fsum = 0; for (i = 0; i < 10; i++) fsum += 0.1f;
    adrp x0, tenth_f@PAGE
    ldr s1, [x0, tenth_f@PAGEOFF]
    fmov s0, wzr                // 0.0f
    mov x1, #10
float_loop:
    fadd s0, s0, s1             // single-precision add
    subs x1, x1, #1
    b.ne float_loop
    fcvt d0, s0                 // printf needs a double
    str d0, [sp]
    adrp x0, f_float@PAGE
    add x0, x0, f_float@PAGEOFF
    bl _printf

    // double dsum = 0; for (i = 0; i < 10; i++) dsum += 0.1;
    adrp x0, tenth@PAGE
    ldr d1, [x0, tenth@PAGEOFF]
    fmov d8, xzr
    mov x1, #10
double_loop:
    fadd d8, d8, d1
    subs x1, x1, #1
    b.ne double_loop
    str d8, [sp]
    adrp x0, f_double@PAGE
    add x0, x0, f_double@PAGEOFF
    bl _printf

    // dsum == 1.0 ?
    fmov d1, #1.0
    fcmp d8, d1
    cset w1, eq
    str x1, [sp]
    adrp x0, f_eq@PAGE
    add x0, x0, f_eq@PAGEOFF
    bl _printf

    // fabs(dsum - 1.0) < 1e-9 ?
    fmov d1, #1.0
    fsub d0, d8, d1
    fabs d0, d0
    adrp x0, eps@PAGE
    ldr d1, [x0, eps@PAGEOFF]
    fcmp d0, d1
    cset w1, mi                 // mi = ordered "less than"
    str x1, [sp]
    adrp x0, f_close@PAGE
    add x0, x0, f_close@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #16
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__const
    .p2align 3
tenth:   .double 0.1
eps:     .double 1e-9
tenth_f: .float 0.1

    .section __TEXT,__cstring
f_float:  .asciz "float  sum = %.17f\n"
f_double: .asciz "double sum = %.17f\n"
f_eq:     .asciz "double sum == 1.0: %d\n"
f_close:  .asciz "fabs(double sum - 1.0) < 1e-9: %d\n"
