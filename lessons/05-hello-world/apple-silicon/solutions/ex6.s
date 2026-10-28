// ex6.s - Exercise 05.6: print only the word "world" out of "Hello, world!\n" (macOS)
// by pointing x1 into the middle of the string.
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   world
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const
msg:
    .ascii "Hello, world!\n"
    .equ msg_len, . - msg
nl:
    .ascii "\n"

    .text
    .p2align 2
_main:
    mov x0, #1
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF         // x1 = &msg[0]
    add x1, x1, #7                  // x1 = &msg[7], the 'w'
    mov x2, #5                      // "world" is 5 bytes
    mov x16, #4
    svc #0x80

    mov x0, #1                      // then a newline
    adrp x1, nl@PAGE
    add x1, x1, nl@PAGEOFF
    mov x2, #1
    mov x16, #4
    svc #0x80

    mov x0, #0
    mov x16, #1
    svc #0x80
