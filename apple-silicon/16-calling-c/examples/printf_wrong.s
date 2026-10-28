// printf_wrong.s - the Linux way of calling printf, which is WRONG on macOS.
//
// We put 2, 3, 5 in w1, w2, w3, as on Linux. On macOS printf never looks
// there for its "..." arguments: it reads them from the stack. To make
// that visible, we first leave 7, 8, 9 in the three stack slots, as if an
// earlier piece of code had left them there.
//
// Build: make printf_wrong
// Run:   ./printf_wrong
// Expected output (not "2 + 3 = 5"!):
//     7 + 8 = 9
// Without the three stores of 7, 8, 9 you would get whatever bytes happen
// to be on the stack, different from run to run, e.g. "-16 + 1838897480 = ...".

    .section __TEXT,__cstring
fmt_sum:
    .asciz  "%d + %d = %d\n"

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #32

    mov     x9, #7                  // "leftover" values in the three slots
    str     x9, [sp]
    mov     x9, #8
    str     x9, [sp, #8]
    mov     x9, #9
    str     x9, [sp, #16]

    adrp    x0, fmt_sum@PAGE
    add     x0, x0, fmt_sum@PAGEOFF
    mov     w1, #2                  // WRONG on macOS: printf ignores x1-x7
    mov     w2, #3                  // for its variadic arguments
    mov     w3, #5
    bl      _printf

    add     sp, sp, #32
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
