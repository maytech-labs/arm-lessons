// stderr.s - writes an error message to stderr and exits with status 1 (macOS).
//
// Build:  make
// Run:    ./stderr; echo $?
//         ./stderr 2>/dev/null; echo $?      (the message disappears)
// Expected output (on stderr):
//   something went wrong
// Exit status (echo $?): 1

    .global _main

    .section __TEXT,__const
msg:
    .ascii "something went wrong\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_main:
    mov x0, #2                      // file descriptor 2 = stderr
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF
    mov x2, #msg_len
    mov x16, #4                     // write(2, msg, msg_len)
    svc #0x80

    mov x0, #1                      // exit status 1: failure
    mov x16, #1
    svc #0x80
