// ex2.s - Exercise 17.2: count how many times a character appears (macOS).
//
// C version:
//     long count_char(const char *s, int c) {
//         long n = 0;
//         for (; *s; s++) if (*s == (char)c) n++;
//         return n;
//     }
//
// Build: make ex2
// Run:   ./ex2
// Expected output:
//     's' appears 4 times in mississippi
//     'i' appears 4 times in mississippi
//     'p' appears 2 times in mississippi
//     'z' appears 0 times in mississippi

    .section __TEXT,__const
text:
    .asciz  "mississippi"
fmt:
    .asciz  "'%c' appears %ld times in %s\n"

    .text
    .p2align 2
// long count_char(const char *s, int c)
count_char:
    and     w1, w1, #0xff
    mov     x2, #0                  // n
count_loop:
    ldrb    w3, [x0], #1
    cbz     w3, count_done
    cmp     w3, w1
    cinc    x2, x2, eq              // n++ if equal
    b       count_loop
count_done:
    mov     x0, x2
    ret

// void report(int c)
report:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     w19, w0
    mov     w1, w0
    adrp    x0, text@PAGE
    add     x0, x0, text@PAGEOFF
    bl      count_char
    mov     x2, x0
    mov     w1, w19
    adrp    x3, text@PAGE
    add     x3, x3, text@PAGEOFF
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    mov     w0, #'s'
    bl      report
    mov     w0, #'i'
    bl      report
    mov     w0, #'p'
    bl      report
    mov     w0, #'z'
    bl      report
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
