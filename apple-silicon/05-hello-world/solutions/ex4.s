// ex4.s - Exercise 05.4: a box drawn with three separate write calls (macOS).
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   +------+
//   | asm! |
//   +------+
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const
edge:
    .ascii "+------+\n"
    .equ edge_len, . - edge
middle:
    .ascii "| asm! |\n"
    .equ middle_len, . - middle

    .text
    .p2align 2
_main:
    mov x0, #1                      // top edge
    adrp x1, edge@PAGE
    add x1, x1, edge@PAGEOFF
    mov x2, #edge_len
    mov x16, #4
    svc #0x80

    mov x0, #1                      // middle
    adrp x1, middle@PAGE
    add x1, x1, middle@PAGEOFF
    mov x2, #middle_len
    mov x16, #4
    svc #0x80

    mov x0, #1                      // bottom edge: the same bytes again
    adrp x1, edge@PAGE
    add x1, x1, edge@PAGEOFF
    mov x2, #edge_len
    mov x16, #4
    svc #0x80

    mov x0, #0
    mov x16, #1                     // exit(0)
    svc #0x80
