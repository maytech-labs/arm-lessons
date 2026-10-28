// result.s - write returns the number of bytes written in x0 (macOS).
// We exit with that number, so echo $? shows it.
//
// Build:  make
// Run:    ./result; echo $?
// Expected output:
//   12345
// Exit status (echo $?): 6     (five digits and a newline)

    .global _main

    .section __TEXT,__const
msg:
    .ascii "12345\n"
    .equ msg_len, . - msg

    .text
    .p2align 2
_main:
    mov x0, #1
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF
    mov x2, #msg_len
    mov x16, #4                     // x0 = write(1, msg, 6)
    svc #0x80
                                    // x0 now holds write's result: 6
    mov x16, #1                     // exit(x0): no mov x0 needed
    svc #0x80
