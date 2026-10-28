// ex6.s - Exercise 05.6: print only the word "world" out of "Hello, world!\n"
// by pointing x1 into the middle of the string.
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   world
// Exit status (echo $?): 0

    .global _start

    .section .rodata
msg:
    .ascii "Hello, world!\n"
    .equ msg_len, . - msg
nl:
    .ascii "\n"

    .text
    .p2align 2
_start:
    mov x0, #1
    adrp x1, msg
    add x1, x1, :lo12:msg           // x1 = &msg[0]
    add x1, x1, #7                  // x1 = &msg[7], the 'w'
    mov x2, #5                      // "world" is 5 bytes
    mov x8, #64
    svc #0

    mov x0, #1                      // then a newline
    adrp x1, nl
    add x1, x1, :lo12:nl
    mov x2, #1
    mov x8, #64
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0
