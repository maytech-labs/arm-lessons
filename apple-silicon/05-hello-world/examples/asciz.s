// asciz.s - .asciz adds a zero byte; see it with objdump, and see why we (macOS)
// subtract one to get the printable length.
//
// Build:  make
// Run:    ./asciz
// Look:   objdump -s -j __const asciz
// Expected output:
//   ascii
//   asciz
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const
a:
    .ascii "ascii\n"                // 6 bytes: a s c i i \n
    .equ a_len, . - a               // 6
z:
    .asciz "asciz\n"                // 7 bytes: a s c i z \n 0
    .equ z_len, . - z - 1           // 7 - 1 = 6: do not print the zero byte

    .text
    .p2align 2
_main:
    mov x0, #1
    adrp x1, a@PAGE
    add x1, x1, a@PAGEOFF
    mov x2, #a_len
    mov x16, #4                     // write(1, a, 6)
    svc #0x80

    mov x0, #1
    adrp x1, z@PAGE
    add x1, x1, z@PAGEOFF
    mov x2, #z_len
    mov x16, #4                     // write(1, z, 6)
    svc #0x80

    mov x0, #0
    mov x16, #1
    svc #0x80
