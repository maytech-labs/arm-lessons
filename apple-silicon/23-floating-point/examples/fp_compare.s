// fp_compare.s - fcmp, the four outcomes, and the NaN trap (lesson 23, macOS)
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
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #32             // room for printf's variadic arguments

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
    str x1, [sp]                // writing w1 zeroed the top of x1: safe to store x1
    str x2, [sp, #8]
    str x3, [sp, #16]
    adrp x0, trap_fmt@PAGE
    add x0, x0, trap_fmt@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #32
    ldp x29, x30, [sp], #16
    ret

// void compare(double a, double b): print which relation holds
compare:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #32
    fcmp d0, d1                 // sets NZCV; d0 and d1 are unchanged
    b.vs compare_unordered      // V=1: at least one is NaN
    b.mi compare_less           // a < b
    b.gt compare_greater        // a > b
    adrp x1, w_equal@PAGE       // only "equal" is left
    add x1, x1, w_equal@PAGEOFF
    b compare_print
compare_less:
    adrp x1, w_less@PAGE
    add x1, x1, w_less@PAGEOFF
    b compare_print
compare_greater:
    adrp x1, w_greater@PAGE
    add x1, x1, w_greater@PAGEOFF
    b compare_print
compare_unordered:
    adrp x1, w_unordered@PAGE
    add x1, x1, w_unordered@PAGEOFF
compare_print:
    str d0, [sp]                // a
    str d1, [sp, #8]            // b
    str x1, [sp, #16]           // word
    adrp x0, cmp_fmt@PAGE
    add x0, x0, cmp_fmt@PAGEOFF
    bl _printf
    add sp, sp, #32
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
cmp_fmt:     .asciz "%4.1f vs %4.1f: %s\n"
trap_fmt:    .asciz "NaN < 1.0 using lt: %d, using mi: %d\nNaN == NaN: %d\n"
w_less:      .asciz "less"
w_greater:   .asciz "greater"
w_equal:     .asciz "equal"
w_unordered: .asciz "unordered"
