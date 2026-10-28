// fp_ops.s - double arithmetic: + - * / sqrt fabs fneg fmadd (lesson 23)
//
// Build: make fp_ops
// Run:   ./fp_ops
// Expected output:
//   a            = 7.500000
//   b            = -2.000000
//   a + b        = 5.500000
//   a - b        = 9.500000
//   a * b        = -15.000000
//   a / b        = -3.750000
//   sqrt(a)      = 2.738613
//   fabs(b)      = 2.000000
//   -a           = -7.500000
//   a * b + 10   = -5.000000
//   pi * r * r   = 12.566371

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp d8, d9, [sp, #16]       // d8, d9 are callee-saved: save them

    fmov d8, #7.5               // double a = 7.5;  (survives calls)
    fmov d9, #-2.0              // double b = -2.0;

    adrp x0, n_a
    add x0, x0, :lo12:n_a
    fmov d0, d8                 // show("a", a)
    bl show

    adrp x0, n_b
    add x0, x0, :lo12:n_b
    fmov d0, d9
    bl show

    adrp x0, n_add
    add x0, x0, :lo12:n_add
    fadd d0, d8, d9             // a + b
    bl show

    adrp x0, n_sub
    add x0, x0, :lo12:n_sub
    fsub d0, d8, d9             // a - b
    bl show

    adrp x0, n_mul
    add x0, x0, :lo12:n_mul
    fmul d0, d8, d9             // a * b
    bl show

    adrp x0, n_div
    add x0, x0, :lo12:n_div
    fdiv d0, d8, d9             // a / b
    bl show

    adrp x0, n_sqrt
    add x0, x0, :lo12:n_sqrt
    fsqrt d0, d8                // sqrt(a), one instruction
    bl show

    adrp x0, n_abs
    add x0, x0, :lo12:n_abs
    fabs d0, d9                 // fabs(b)
    bl show

    adrp x0, n_neg
    add x0, x0, :lo12:n_neg
    fneg d0, d8                 // -a
    bl show

    adrp x0, n_fma
    add x0, x0, :lo12:n_fma
    fmov d1, #10.0
    fmadd d0, d8, d9, d1        // d0 = d1 + d8 * d9 = 10 + a * b
    bl show

    adrp x0, n_area
    add x0, x0, :lo12:n_area
    adrp x1, pi                 // pi is not an fmov immediate:
    ldr d0, [x1, :lo12:pi]      //   load it from .rodata
    fmov d1, #2.0               // r = 2.0
    fmul d0, d0, d1             // pi * r
    fmul d0, d0, d1             // pi * r * r
    bl show

    mov w0, #0
    ldp d8, d9, [sp, #16]       // restore the caller's d8, d9
    ldp x29, x30, [sp], #32
    ret

// void show(const char *name, double value)
show:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x1, x0                  // printf(fmt, name, value):
    adrp x0, fmt                //   name moves to x1, value stays in d0
    add x0, x0, :lo12:fmt
    bl printf
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
    .p2align 3
pi:
    .double 3.141592653589793
fmt:    .asciz "%-12s = %f\n"
n_a:    .asciz "a"
n_b:    .asciz "b"
n_add:  .asciz "a + b"
n_sub:  .asciz "a - b"
n_mul:  .asciz "a * b"
n_div:  .asciz "a / b"
n_sqrt: .asciz "sqrt(a)"
n_abs:  .asciz "fabs(b)"
n_neg:  .asciz "-a"
n_fma:  .asciz "a * b + 10"
n_area: .asciz "pi * r * r"
