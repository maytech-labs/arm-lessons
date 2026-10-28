// ex2.s - Exercise 05.2: print a greeting with your name.
//
// Build:  make
// Run:    ./ex2
// Expected output:
//   Hi, my name is Ada.
// Exit status (echo $?): 0

    .global _start

    .section .rodata
msg:
    .ascii "Hi, my name is Ada.\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_start:
    mov x0, #1                      // stdout
    adrp x1, msg
    add x1, x1, :lo12:msg
    mov x2, #msg_len
    mov x8, #64                     // write(1, msg, msg_len)
    svc #0

    mov x0, #0
    mov x8, #93                     // exit(0)
    svc #0
