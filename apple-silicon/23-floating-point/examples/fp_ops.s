// fp_ops.s - double arithmetic: + - * / sqrt fabs fneg fmadd (lesson 23, macOS)
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
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp d8, d9, [sp, #16]       // d8, d9 are callee-saved: save them

    fmov d8, #7.5               // double a = 7.5;  (survives calls)
    fmov d9, #-2.0              // double b = -2.0;

    adrp x0, n_a@PAGE
    add x0, x0, n_a@PAGEOFF
    fmov d0, d8                 // show("a", a)
    bl show

    adrp x0, n_b@PAGE
    add x0, x0, n_b@PAGEOFF
    fmov d0, d9
    bl show

    adrp x0, n_add@PAGE
    add x0, x0, n_add@PAGEOFF
    fadd d0, d8, d9             // a + b
    bl show

    adrp x0, n_sub@PAGE
    add x0, x0, n_sub@PAGEOFF
    fsub d0, d8, d9             // a - b
    bl show

    adrp x0, n_mul@PAGE
    add x0, x0, n_mul@PAGEOFF
    fmul d0, d8, d9             // a * b
    bl show

    adrp x0, n_div@PAGE
    add x0, x0, n_div@PAGEOFF
    fdiv d0, d8, d9             // a / b
    bl show

    adrp x0, n_sqrt@PAGE
    add x0, x0, n_sqrt@PAGEOFF
    fsqrt d0, d8                // sqrt(a), one instruction
    bl show

    adrp x0, n_abs@PAGE
    add x0, x0, n_abs@PAGEOFF
    fabs d0, d9                 // fabs(b)
    bl show

    adrp x0, n_neg@PAGE
    add x0, x0, n_neg@PAGEOFF
    fneg d0, d8                 // -a
    bl show

    adrp x0, n_fma@PAGE
    add x0, x0, n_fma@PAGEOFF
    fmov d1, #10.0
    fmadd d0, d8, d9, d1        // d0 = d1 + d8 * d9 = 10 + a * b
    bl show

    adrp x0, n_area@PAGE
    add x0, x0, n_area@PAGEOFF
    adrp x1, pi@PAGE            // pi is not an fmov immediate:
    ldr d0, [x1, pi@PAGEOFF]    //   load it from __TEXT,__const
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
    sub sp, sp, #16             // two variadic arguments
    str x0, [sp]                // name
    str d0, [sp, #8]            // value
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    bl _printf
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__const
    .p2align 3
pi:
    .double 3.141592653589793

    .section __TEXT,__cstring
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
