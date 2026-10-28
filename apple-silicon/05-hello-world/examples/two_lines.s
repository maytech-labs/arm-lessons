// two_lines.s - two separate messages, two separate write calls (macOS).
//
// Build:  make
// Run:    ./two_lines
// Expected output:
//   Roses are red,
//   registers are too.
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const
line1:
    .ascii "Roses are red,\n"
    .equ line1_len, . - line1
line2:
    .ascii "registers are too.\n"
    .equ line2_len, . - line2

    .text
    .p2align 2
_main:
    mov x0, #1                      // write(1, line1, line1_len)
    adrp x1, line1@PAGE
    add x1, x1, line1@PAGEOFF
    mov x2, #line1_len
    mov x16, #4
    svc #0x80

    mov x0, #1                      // write(1, line2, line2_len)
    adrp x1, line2@PAGE             // x0 must be set again: write put its
    add x1, x1, line2@PAGEOFF       // result in x0 (see the lesson)
    mov x2, #line2_len
    mov x16, #4
    svc #0x80

    mov x0, #0
    mov x16, #1                     // exit(0)
    svc #0x80
