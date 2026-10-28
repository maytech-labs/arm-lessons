// ex7.s - Exercise 06.7: hello world with labels to put breakpoints on (macOS).
//
// Build:  make
// Debug:  lldb ./ex7  then   b before_write   run   (inspect)
//                            b before_exit    continue   (inspect)
// Expected output:
//   Hello, world!
// Exit status (echo $?): 0

    .global _main

    .data
msg:
    .ascii "Hello, world!\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_main:
    mov x0, #1
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF
    mov x2, #msg_len
    mov x16, #4
before_write:                   // a label is just a name for this address
    svc #0x80                   // write(1, msg, 14)

    mov x0, #0
    mov x16, #1
before_exit:
    svc #0x80                   // exit(0)
