// ex7.s - add 0.1 ten times as float and as double, compare with 1.0 (lesson 23, exercise 23.7)
//
// Build: make ex7
// Run:   ./ex7
// Expected output:
//   float  sum = 1.00000011920928955
//   double sum = 0.99999999999999989
//   double sum == 1.0: 0
//   fabs(double sum - 1.0) < 1e-9: 1

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]

    // float fsum = 0; for (i = 0; i < 10; i++) fsum += 0.1f;
    adrp x0, tenth_f
    ldr s1, [x0, :lo12:tenth_f]
    fmov s0, wzr                // 0.0f
    mov x1, #10
float_loop:
    fadd s0, s0, s1             // single-precision add
    subs x1, x1, #1
    b.ne float_loop
    fcvt d0, s0                 // printf needs a double
    adrp x0, f_float
    add x0, x0, :lo12:f_float
    bl printf

    // double dsum = 0; for (i = 0; i < 10; i++) dsum += 0.1;
    adrp x0, tenth
    ldr d1, [x0, :lo12:tenth]
    fmov d8, xzr
    mov x1, #10
double_loop:
    fadd d8, d8, d1
    subs x1, x1, #1
    b.ne double_loop
    fmov d0, d8
    adrp x0, f_double
    add x0, x0, :lo12:f_double
    bl printf

    // dsum == 1.0 ?
    fmov d1, #1.0
    fcmp d8, d1
    cset w1, eq
    adrp x0, f_eq
    add x0, x0, :lo12:f_eq
    bl printf

    // fabs(dsum - 1.0) < 1e-9 ?
    fmov d1, #1.0
    fsub d0, d8, d1
    fabs d0, d0
    adrp x0, eps
    ldr d1, [x0, :lo12:eps]
    fcmp d0, d1
    cset w1, mi                 // mi = ordered "less than"
    adrp x0, f_close
    add x0, x0, :lo12:f_close
    bl printf

    mov w0, #0
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
    .p2align 3
tenth:   .double 0.1
eps:     .double 1e-9
tenth_f: .float 0.1
f_float:  .asciz "float  sum = %.17f\n"
f_double: .asciz "double sum = %.17f\n"
f_eq:     .asciz "double sum == 1.0: %d\n"
f_close:  .asciz "fabs(double sum - 1.0) < 1e-9: %d\n"
