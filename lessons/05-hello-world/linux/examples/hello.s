// hello.s - prints "Hello, world!" and exits with status 0.
//
// Build:  make
// Run:    ./hello
// Expected output:
//   Hello, world!
// Exit status (echo $?): 0

    .global _start

    .data                           // initialised data goes here
msg:
    .ascii "Hello, world!\n"        // the 14 bytes we will print
    .equ msg_len, . - msg           // msg_len = (here) - (start of msg) = 14

    .text
    .p2align 2
_start:
    mov x0, #1                      // argument 1: file descriptor 1 = stdout
    adrp x1, msg                    // argument 2: the address of msg...
    add x1, x1, :lo12:msg           // ...built in two steps (see the lesson)
    mov x2, #msg_len                // argument 3: how many bytes to write
    mov x8, #64                     // 64 = write
    svc #0                          // write(1, msg, 14)

    mov x0, #0                      // exit status 0: success
    mov x8, #93                     // 93 = exit
    svc #0                          // exit(0)
