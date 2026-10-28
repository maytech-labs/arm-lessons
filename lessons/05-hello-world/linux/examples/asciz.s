// asciz.s - .asciz adds a zero byte; see it with objdump, and see why we
// subtract one to get the printable length.
//
// Build:  make
// Run:    ./asciz
// Look:   objdump -s -j .rodata asciz
// Expected output:
//   ascii
//   asciz
// Exit status (echo $?): 0

    .global _start

    .section .rodata
a:
    .ascii "ascii\n"                // 6 bytes: a s c i i \n
    .equ a_len, . - a               // 6
z:
    .asciz "asciz\n"                // 7 bytes: a s c i z \n 0
    .equ z_len, . - z - 1           // 7 - 1 = 6: do not print the zero byte

    .text
    .p2align 2
_start:
    mov x0, #1
    adrp x1, a
    add x1, x1, :lo12:a
    mov x2, #a_len
    mov x8, #64                     // write(1, a, 6)
    svc #0

    mov x0, #1
    adrp x1, z
    add x1, x1, :lo12:z
    mov x2, #z_len
    mov x8, #64                     // write(1, z, 6)
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0
