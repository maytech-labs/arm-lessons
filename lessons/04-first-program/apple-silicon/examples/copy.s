// copy.s - moves a value through several registers before exiting with it (macOS).
//
// Build:  make
// Run:    ./copy; echo $?
// Exit status (echo $?): 7

    .global _main
    .text
    .p2align 2

_main:
    mov x3, #7                  // x3 = 7
    mov x4, x3                  // x4 = x3   (copy a register, not a constant)
    mov x0, x4                  // x0 = x4   (the exit status must be in x0)
    mov x16, #1                 // exit
    svc #0x80
