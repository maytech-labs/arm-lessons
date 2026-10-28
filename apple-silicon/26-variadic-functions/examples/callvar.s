// callvar.s - recap: calling a variadic function (printf) on macOS arm64.
//
// The C version:
//     printf("%d + %d = %d, pi is about %.2f, name %s\n", 2, 3, 5, 3.14159, "Ada");
//     printf("%d %d %d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6, 7, 8, 9);
//
// On macOS the named argument (the format) goes in x0 as usual, but EVERY
// variadic argument goes on the stack, one 8-byte slot each, in order,
// whatever its type (int, double or pointer).
//
// Build and run:
//     make callvar
//     ./callvar
// Expected output:
//     2 + 3 = 5, pi is about 3.14, name Ada
//     1 2 3 4 5 6 7 8 9

    .text
    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // First call: five variadic arguments = 40 bytes, rounded up to 48.
    sub     sp, sp, #48
    mov     x9, #2
    str     x9, [sp]                // slot 0: 2
    mov     x9, #3
    str     x9, [sp, #8]            // slot 1: 3
    mov     x9, #5
    str     x9, [sp, #16]           // slot 2: 5
    adrp    x9, pi@PAGE
    ldr     d0, [x9, pi@PAGEOFF]
    str     d0, [sp, #24]           // slot 3: the double, also on the stack
    adrp    x9, name@PAGE
    add     x9, x9, name@PAGEOFF
    str     x9, [sp, #32]           // slot 4: the pointer
    adrp    x0, fmt1@PAGE
    add     x0, x0, fmt1@PAGEOFF    // x0 = format (named: in a register)
    bl      _printf
    add     sp, sp, #48

    // Second call: nine ints = 72 bytes, rounded up to 80.
    sub     sp, sp, #80
    mov     x9, #1
    mov     x10, #2
    stp     x9, x10, [sp]
    mov     x9, #3
    mov     x10, #4
    stp     x9, x10, [sp, #16]
    mov     x9, #5
    mov     x10, #6
    stp     x9, x10, [sp, #32]
    mov     x9, #7
    mov     x10, #8
    stp     x9, x10, [sp, #48]
    mov     x9, #9
    str     x9, [sp, #64]
    adrp    x0, fmt2@PAGE
    add     x0, x0, fmt2@PAGEOFF
    bl      _printf
    add     sp, sp, #80

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
fmt1:
    .asciz  "%d + %d = %d, pi is about %.2f, name %s\n"
fmt2:
    .asciz  "%d %d %d %d %d %d %d %d %d\n"
name:
    .asciz  "Ada"

    .section __TEXT,__const
    .p2align 3
pi:
    .double 3.14159
