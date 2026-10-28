// fp_compare.s - fcmp, the four outcomes, and the NaN trap (lesson 23)
//
// Build: make fp_compare
// Run:   ./fp_compare
// Expected output:
//    1.0 vs  2.0: less
//    2.0 vs  1.0: greater
//    2.0 vs  2.0: equal
//    nan vs  1.0: unordered
//    nan vs  nan: unordered
//   NaN < 1.0 using lt: 1, using mi: 0
//   NaN == NaN: 0

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    fmov d0, #1.0               // compare(1.0, 2.0)
    fmov d1, #2.0
    bl compare
    fmov d0, #2.0               // compare(2.0, 1.0)
    fmov d1, #1.0
    bl compare
    fmov d0, #2.0               // compare(2.0, 2.0)
    fmov d1, #2.0
    bl compare

    fmov d0, xzr                // 0.0
    fdiv d0, d0, d0             // 0.0 / 0.0 = NaN (no crash, no trap)
    fmov d1, #1.0
    bl compare                  // compare(NaN, 1.0)

    fmov d0, xzr
    fdiv d0, d0, d0             // NaN
    fmov d1, d0
    bl compare                  // compare(NaN, NaN)

    // The trap: after fcmp with a NaN, "lt" is TRUE, "mi" is false.
    fmov d0, xzr
    fdiv d0, d0, d0             // d0 = NaN
    fmov d1, #1.0
    fcmp d0, d1
    cset w1, lt                 // wrong way to test a < b
    cset w2, mi                 // right way to test a < b
    fcmp d0, d0
    cset w3, eq                 // NaN == NaN ?
    adrp x0, trap_fmt
    add x0, x0, :lo12:trap_fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// void compare(double a, double b): print which relation holds
compare:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    fcmp d0, d1                 // sets NZCV; d0 and d1 are unchanged
    b.vs compare_unordered      // V=1: at least one is NaN
    b.mi compare_less           // a < b
    b.gt compare_greater        // a > b
    adrp x1, w_equal            // only "equal" is left
    add x1, x1, :lo12:w_equal
    b compare_print
compare_less:
    adrp x1, w_less
    add x1, x1, :lo12:w_less
    b compare_print
compare_greater:
    adrp x1, w_greater
    add x1, x1, :lo12:w_greater
    b compare_print
compare_unordered:
    adrp x1, w_unordered
    add x1, x1, :lo12:w_unordered
compare_print:
    adrp x0, cmp_fmt            // printf(cmp_fmt, a, b, word)
    add x0, x0, :lo12:cmp_fmt   // a, b still in d0, d1; word in x1
    bl printf
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
cmp_fmt:     .asciz "%4.1f vs %4.1f: %s\n"
trap_fmt:    .asciz "NaN < 1.0 using lt: %d, using mi: %d\nNaN == NaN: %d\n"
w_less:      .asciz "less"
w_greater:   .asciz "greater"
w_equal:     .asciz "equal"
w_unordered: .asciz "unordered"
