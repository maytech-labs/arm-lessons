// result.s - write returns the number of bytes written in x0.
// We exit with that number, so echo $? shows it.
//
// Build:  make
// Run:    ./result; echo $?
// Expected output:
//   12345
// Exit status (echo $?): 6     (five digits and a newline)

    .global _start

    .section .rodata
msg:
    .ascii "12345\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_start:
    mov x0, #1
    adrp x1, msg
    add x1, x1, :lo12:msg
    mov x2, #msg_len
    mov x8, #64                     // x0 = write(1, msg, 6)
    svc #0
                                    // x0 now holds write's result: 6
    mov x8, #93                     // exit(x0): no mov x0 needed
    svc #0
