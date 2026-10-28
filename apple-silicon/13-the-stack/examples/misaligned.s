// misaligned.s - a broken program: it moves sp by 8, which breaks the (macOS)
// 16-byte rule, and the next access through sp crashes.
//
// Build:  make
// Run:    ./misaligned; echo $?
// Exit status (echo $?): 138, after "Bus error" (SIGBUS is signal 10 on macOS)

    .global _main
    .text
    .p2align 2

_main:
    sub sp, sp, #8              // WRONG: sp is now 8 bytes off a multiple of 16
    mov x0, #42
    str x0, [sp]                // any load/store through a misaligned sp faults
    add sp, sp, #8
    mov x16, #1
    svc #0x80
