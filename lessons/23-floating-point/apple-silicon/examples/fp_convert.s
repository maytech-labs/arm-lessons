// fp_convert.s - int <-> double <-> float conversions, C cast rules (lesson 23, macOS)
//
// Build: make fp_convert
// Run:   ./fp_convert
// Expected output:
//   (double)7 / 2         = 3.500000
//   7 / 2 with integers   = 3
//   (long)2.7             = 2
//   (long)-2.7            = -2
//   (unsigned long)-2.7   = 0
//   (long)1e20            = 9223372036854775807
//   (double)(long)-1      = -1.000000
//   (double)(ulong)-1     = 18446744073709551616.000000
//   0.1 as a double       = 0.10000000000000001
//   0.1 as a float        = 0.10000000149011612

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16             // room for printf's one variadic argument

    // (double)7 / 2
    mov x1, #7
    scvtf d0, x1                // signed integer -> double: 7.0
    fmov d1, #2.0
    fdiv d0, d0, d1             // 3.5
    str d0, [sp]                // the one variadic argument goes on the stack
    adrp x0, f1@PAGE
    add x0, x0, f1@PAGEOFF
    bl _printf

    // 7 / 2 with integers
    mov x1, #7
    mov x2, #2
    sdiv x1, x1, x2             // 3: integer division throws away the .5
    str x1, [sp]
    adrp x0, f2@PAGE
    add x0, x0, f2@PAGEOFF
    bl _printf

    // (long)2.7
    adrp x0, k_2_7@PAGE
    ldr d0, [x0, k_2_7@PAGEOFF]
    fcvtzs x1, d0               // toward zero: 2
    str x1, [sp]
    adrp x0, f3@PAGE
    add x0, x0, f3@PAGEOFF
    bl _printf

    // (long)-2.7
    adrp x0, k_2_7@PAGE
    ldr d0, [x0, k_2_7@PAGEOFF]
    fneg d0, d0                 // -2.7
    fcvtzs x1, d0               // toward zero: -2 (not -3)
    str x1, [sp]
    adrp x0, f4@PAGE
    add x0, x0, f4@PAGEOFF
    bl _printf

    // (unsigned long)-2.7
    adrp x0, k_2_7@PAGE
    ldr d0, [x0, k_2_7@PAGEOFF]
    fneg d0, d0
    fcvtzu x1, d0               // negative -> unsigned: clamps to 0
    str x1, [sp]
    adrp x0, f5@PAGE
    add x0, x0, f5@PAGEOFF
    bl _printf

    // (long)1e20 - too big for a long
    adrp x0, k_1e20@PAGE
    ldr d0, [x0, k_1e20@PAGEOFF]
    fcvtzs x1, d0               // clamps to the largest long
    str x1, [sp]
    adrp x0, f6@PAGE
    add x0, x0, f6@PAGEOFF
    bl _printf

    // (double)(long)-1 and (double)(unsigned long)-1: same bits, two answers
    mov x1, #-1
    scvtf d0, x1                // read as signed:   -1.0
    str d0, [sp]
    adrp x0, f7@PAGE
    add x0, x0, f7@PAGEOFF
    bl _printf
    mov x1, #-1
    ucvtf d0, x1                // read as unsigned: 2^64 - 1, rounds to 2^64
    str d0, [sp]
    adrp x0, f8@PAGE
    add x0, x0, f8@PAGEOFF
    bl _printf

    // 0.1 stored as a double, and 0.1 stored as a float then widened
    adrp x0, k_tenth@PAGE
    ldr d0, [x0, k_tenth@PAGEOFF]
    str d0, [sp]
    adrp x0, f9@PAGE
    add x0, x0, f9@PAGEOFF
    bl _printf
    adrp x0, k_tenth_f@PAGE
    ldr s0, [x0, k_tenth_f@PAGEOFF]
    fcvt d0, s0                 // float -> double (exact, but shows the float's error)
    str d0, [sp]
    adrp x0, f10@PAGE
    add x0, x0, f10@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__const
    .p2align 3
k_2_7:     .double 2.7
k_1e20:    .double 1e20
k_tenth:   .double 0.1
k_tenth_f: .float 0.1

    .section __TEXT,__cstring
f1:  .asciz "(double)7 / 2         = %f\n"
f2:  .asciz "7 / 2 with integers   = %ld\n"
f3:  .asciz "(long)2.7             = %ld\n"
f4:  .asciz "(long)-2.7            = %ld\n"
f5:  .asciz "(unsigned long)-2.7   = %lu\n"
f6:  .asciz "(long)1e20            = %ld\n"
f7:  .asciz "(double)(long)-1      = %f\n"
f8:  .asciz "(double)(ulong)-1     = %f\n"
f9:  .asciz "0.1 as a double       = %.17f\n"
f10: .asciz "0.1 as a float        = %.17f\n"
