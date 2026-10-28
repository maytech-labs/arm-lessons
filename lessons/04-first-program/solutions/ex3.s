// ex3.s - Exercise 04.3: pass 9 along a chain of registers, then exit with it.
//
// Build:  make
// Run:    ./ex3; echo $?
// Exit status (echo $?): 9

    .global _start
    .text
    .p2align 2

_start:
    mov x2, #9                  // x2 = 9
    mov x5, x2                  // x5 = 9
    mov x11, x5                 // x11 = 9
    mov x0, x11                 // x0 = 9, the exit status
    mov x8, #93                 // exit
    svc #0
