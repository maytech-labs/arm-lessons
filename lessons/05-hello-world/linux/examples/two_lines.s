// two_lines.s - two separate messages, two separate write calls.
//
// Build:  make
// Run:    ./two_lines
// Expected output:
//   Roses are red,
//   registers are too.
// Exit status (echo $?): 0

    .global _start

    .section .rodata
line1:
    .ascii "Roses are red,\n"
    .equ line1_len, . - line1
line2:
    .ascii "registers are too.\n"
    .equ line2_len, . - line2

    .text
    .p2align 2
_start:
    mov x0, #1                      // write(1, line1, line1_len)
    adrp x1, line1
    add x1, x1, :lo12:line1
    mov x2, #line1_len
    mov x8, #64
    svc #0

    mov x0, #1                      // write(1, line2, line2_len)
    adrp x1, line2                  // x0 must be set again: write put its
    add x1, x1, :lo12:line2         // result in x0 (see the lesson)
    mov x2, #line2_len
    mov x8, #64
    svc #0

    mov x0, #0
    mov x8, #93                     // exit(0)
    svc #0
