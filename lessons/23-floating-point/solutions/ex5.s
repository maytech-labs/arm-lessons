// ex5.s - real roots of a x^2 + b x + c, three test cases (lesson 23, exercise 23.5)
//
// Build: make ex5
// Run:   ./ex5
// Expected output:
//   1 x^2 + -3 x + 2: two roots 2.000000 and 1.000000
//   1 x^2 + 2 x + 1: one root -1.000000
//   1 x^2 + 2 x + 5: no real roots

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    fmov d0, #1.0
    fmov d1, #-3.0
    fmov d2, #2.0
    bl solve
    fmov d0, #1.0
    fmov d1, #2.0
    fmov d2, #1.0
    bl solve
    fmov d0, #1.0
    fmov d1, #2.0
    fmov d2, #5.0
    bl solve

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// void solve(double a, double b, double c)
solve:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp d8, d9, [sp, #16]
    str d10, [sp, #32]
    fmov d8, d0                 // a
    fmov d9, d1                 // b
    fmov d10, d2                // c

    adrp x0, f_eq               // printf("%g x^2 + %g x + %g: ", a, b, c)
    add x0, x0, :lo12:f_eq      // a, b, c are already in d0, d1, d2
    bl printf

    fmul d0, d9, d9             // b * b
    fmov d1, #4.0
    fmul d1, d1, d8             // 4a
    fmsub d0, d1, d10, d0       // disc = b*b - 4a*c
    fcmp d0, #0.0
    b.mi solve_none             // disc < 0
    b.eq solve_one              // disc == 0

    fsqrt d0, d0                // s = sqrt(disc)
    fneg d1, d9                 // -b
    fadd d2, d8, d8             // 2a
    fadd d3, d1, d0             // -b + s
    fsub d4, d1, d0             // -b - s
    fdiv d0, d3, d2             // root1
    fdiv d1, d4, d2             // root2
    adrp x0, f_two
    add x0, x0, :lo12:f_two
    bl printf
    b solve_done

solve_one:
    fneg d0, d9
    fadd d1, d8, d8
    fdiv d0, d0, d1             // -b / 2a
    adrp x0, f_one
    add x0, x0, :lo12:f_one
    bl printf
    b solve_done

solve_none:
    adrp x0, f_none
    add x0, x0, :lo12:f_none
    bl printf

solve_done:
    ldr d10, [sp, #32]
    ldp d8, d9, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section .rodata
f_eq:   .asciz "%g x^2 + %g x + %g: "
f_two:  .asciz "two roots %f and %f\n"
f_one:  .asciz "one root %f\n"
f_none: .asciz "no real roots\n"
