// rodata.s - like hello.s, but the message lives in read-only data (macOS).
//
// Build:  make
// Run:    ./rodata
// Expected output:
//   Constants belong in .rodata
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const         // read-only data: writing here would crash
msg:
    .ascii "Constants belong in .rodata\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_main:
    mov x0, #1                      // stdout
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF         // x1 = &msg
    mov x2, #msg_len                // length
    mov x16, #4                     // write
    svc #0x80

    mov x0, #0
    mov x16, #1                     // exit(0)
    svc #0x80
