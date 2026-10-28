// ex7.s - Exercise 17.7: one number in several bases, with my_itoa (macOS).
//
// Prints 2026 in bases 2, 8, 10, 16 and 36, and libc's %o / %d / %x next to
// the bases printf knows.
//
// Build: make ex7
// Run:   ./ex7
// Expected output:
//     base 2: 11111101010
//     base 8: 3752 (printf: 3752)
//     base 10: 2026 (printf: 2026)
//     base 16: 7ea (printf: 7ea)
//     base 36: 1ka

    .section __TEXT,__const
fmt_plain:
    .asciz  "base %d: %s\n"
fmt_o:
    .asciz  "base %d: %s (printf: %lo)\n"
fmt_d:
    .asciz  "base %d: %s (printf: %ld)\n"
fmt_x:
    .asciz  "base %d: %s (printf: %lx)\n"

    .bss
buf:
    .space  72

    .text
    .p2align 2
// char *my_itoa(long value, char *buf, int base)   (as in the lesson)
my_itoa:
    mov     x3, x1
    mov     x4, x0
    mov     w5, w2
    tbz     x0, #63, itoa_digits
    mov     w6, #'-'
    strb    w6, [x3], #1
    neg     x4, x0
itoa_digits:
    mov     x8, x3
itoa_loop:
    udiv    x6, x4, x5
    msub    x7, x6, x5, x4
    cmp     x7, #10
    b.lo    itoa_decimal
    add     x7, x7, #('a' - 10)
    b       itoa_store
itoa_decimal:
    add     x7, x7, #'0'
itoa_store:
    strb    w7, [x3], #1
    mov     x4, x6
    cbnz    x4, itoa_loop
    strb    wzr, [x3]
    sub     x3, x3, #1
itoa_rev:
    cmp     x8, x3
    b.hs    itoa_done
    ldrb    w6, [x8]
    ldrb    w7, [x3]
    strb    w7, [x8], #1
    strb    w6, [x3], #-1
    b       itoa_rev
itoa_done:
    mov     x0, x1
    ret

// void show(int base, const char *fmt): convert 2026, then
// printf(fmt, base, buf, 2026)
show:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     w19, w0                 // base
    mov     x20, x1                 // fmt
    mov     w2, w0
    adrp    x1, buf@PAGE
    add     x1, x1, buf@PAGEOFF
    mov     x0, #2026
    bl      my_itoa
    mov     x2, x0                  // %s
    mov     w1, w19                 // %d
    mov     x3, #2026               // printf's own conversion (if used)
    mov     x0, x20
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    mov     w0, #2
    adrp    x1, fmt_plain@PAGE
    add     x1, x1, fmt_plain@PAGEOFF
    bl      show
    mov     w0, #8
    adrp    x1, fmt_o@PAGE
    add     x1, x1, fmt_o@PAGEOFF
    bl      show
    mov     w0, #10
    adrp    x1, fmt_d@PAGE
    add     x1, x1, fmt_d@PAGEOFF
    bl      show
    mov     w0, #16
    adrp    x1, fmt_x@PAGE
    add     x1, x1, fmt_x@PAGEOFF
    bl      show
    mov     w0, #36
    adrp    x1, fmt_plain@PAGE
    add     x1, x1, fmt_plain@PAGEOFF
    bl      show
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
