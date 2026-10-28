// ex2.s - Exercise 05.2: print a greeting with your name (macOS).
//
// Build:  make
// Run:    ./ex2
// Expected output:
//   Hi, my name is Ada.
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const
msg:
    .ascii "Hi, my name is Ada.\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_main:
    mov x0, #1                      // stdout
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF
    mov x2, #msg_len
    mov x16, #4                     // write(1, msg, msg_len)
    svc #0x80

    mov x0, #0
    mov x16, #1                     // exit(0)
    svc #0x80
