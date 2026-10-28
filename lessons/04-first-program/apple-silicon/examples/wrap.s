// wrap.s - exits with 300, but the shell only sees the low 8 bits (macOS).
//
// Build:  make
// Run:    ./wrap; echo $?
// Exit status (echo $?): 44     (300 = 256 + 44)

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #300                // ask for exit status 300
    mov x16, #1
    svc #0x80
