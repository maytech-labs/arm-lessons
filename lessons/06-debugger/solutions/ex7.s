// ex7.s - Exercise 06.7: hello world with labels to put breakpoints on.
//
// Build:  make
// Debug:  gdb ./ex7   then   break before_write   run   (inspect)
//                            break before_exit    continue   (inspect)
// Expected output:
//   Hello, world!
// Exit status (echo $?): 0

    .global _start

    .data
msg:
    .ascii "Hello, world!\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_start:
    mov x0, #1
    adrp x1, msg
    add x1, x1, :lo12:msg
    mov x2, #msg_len
    mov x8, #64
before_write:                   // a label is just a name for this address
    svc #0                      // write(1, msg, 14)

    mov x0, #0
    mov x8, #93
before_exit:
    svc #0                      // exit(0)
