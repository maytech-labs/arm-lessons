// stderr.s - writes an error message to stderr and exits with status 1.
//
// Build:  make
// Run:    ./stderr; echo $?
//         ./stderr 2>/dev/null; echo $?      (the message disappears)
// Expected output (on stderr):
//   something went wrong
// Exit status (echo $?): 1

    .global _start

    .section .rodata
msg:
    .ascii "something went wrong\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_start:
    mov x0, #2                      // file descriptor 2 = stderr
    adrp x1, msg
    add x1, x1, :lo12:msg
    mov x2, #msg_len
    mov x8, #64                     // write(2, msg, msg_len)
    svc #0

    mov x0, #1                      // exit status 1: failure
    mov x8, #93
    svc #0
