// ex4.s - Exercise 06.4: broken.s with the bug fixed. Prints "Hi!".
//
// The bug: broken.s put the buffer address in x0 and the fd in x1. write
// wants the fd in x0 and the address in x1.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   Hi!
// Exit status (echo $?): 0

    .global _start

    .data
msg:
    .ascii "Hi!\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_start:
    mov x0, #1                  // x0 = fd 1 (stdout)
    adrp x1, msg                // x1 = address of msg
    add x1, x1, :lo12:msg
    mov x2, #msg_len            // x2 = 4 bytes
    mov x8, #64                 // write
    svc #0                      // write(1, msg, 4)

    mov x0, #0
    mov x8, #93                 // exit(0)
    svc #0
