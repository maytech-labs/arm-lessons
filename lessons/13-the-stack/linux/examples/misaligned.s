// misaligned.s - a broken program: it moves sp by 8, which breaks the
// 16-byte rule, and the next access through sp crashes.
//
// Build:  make
// Run:    ./misaligned; echo $?
// Exit status (echo $?): 135, after "Bus error" (SIGBUS = signal 7)

    .global _start
    .text
    .p2align 2

_start:
    sub sp, sp, #8              // WRONG: sp is now 8 bytes off a multiple of 16
    mov x0, #42
    str x0, [sp]                // any load/store through a misaligned sp faults
    add sp, sp, #8
    mov x8, #93
    svc #0
