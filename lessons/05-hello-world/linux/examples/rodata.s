// rodata.s - like hello.s, but the message lives in read-only data.
//
// Build:  make
// Run:    ./rodata
// Expected output:
//   Constants belong in .rodata
// Exit status (echo $?): 0

    .global _start

    .section .rodata                // read-only data: writing here would crash
msg:
    .ascii "Constants belong in .rodata\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_start:
    mov x0, #1                      // stdout
    adrp x1, msg
    add x1, x1, :lo12:msg           // x1 = &msg
    mov x2, #msg_len                // length
    mov x8, #64                     // write
    svc #0

    mov x0, #0
    mov x8, #93                     // exit(0)
    svc #0
