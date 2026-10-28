// wrap.s - exits with 300, but the shell only sees the low 8 bits.
//
// Build:  make
// Run:    ./wrap; echo $?
// Exit status (echo $?): 44     (300 = 256 + 44)

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #300                // ask for exit status 300
    mov x8, #93
    svc #0
