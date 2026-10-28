// hello.s - prints "Hello, world!" and exits with status 0 (macOS).
//
// Build:  make
// Run:    ./hello
// Expected output:
//   Hello, world!
// Exit status (echo $?): 0

    .global _main

    .data                           // initialised data goes here
msg:
    .ascii "Hello, world!\n"        // the 14 bytes we will print
    .equ msg_len, . - msg           // msg_len = (here) - (start of msg) = 14

    .text
    .p2align 2
_main:
    mov x0, #1                      // argument 1: file descriptor 1 = stdout
    adrp x1, msg@PAGE               // argument 2: the address of msg...
    add x1, x1, msg@PAGEOFF         // ...built in two steps (see the lesson)
    mov x2, #msg_len                // argument 3: how many bytes to write
    mov x16, #4                     // 4 = write
    svc #0x80                       // write(1, msg, 14)

    mov x0, #0                      // exit status 0: success
    mov x16, #1                     // 1 = exit
    svc #0x80                       // exit(0)
