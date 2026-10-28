// ex4.s - Exercise 05.4: a box drawn with three separate write calls.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   +------+
//   | asm! |
//   +------+
// Exit status (echo $?): 0

    .global _start

    .section .rodata
edge:
    .ascii "+------+\n"
    .equ edge_len, . - edge
middle:
    .ascii "| asm! |\n"
    .equ middle_len, . - middle

    .text
    .p2align 2
_start:
    mov x0, #1                      // top edge
    adrp x1, edge
    add x1, x1, :lo12:edge
    mov x2, #edge_len
    mov x8, #64
    svc #0

    mov x0, #1                      // middle
    adrp x1, middle
    add x1, x1, :lo12:middle
    mov x2, #middle_len
    mov x8, #64
    svc #0

    mov x0, #1                      // bottom edge: the same bytes again
    adrp x1, edge
    add x1, x1, :lo12:edge
    mov x2, #edge_len
    mov x8, #64
    svc #0

    mov x0, #0
    mov x8, #93                     // exit(0)
    svc #0
