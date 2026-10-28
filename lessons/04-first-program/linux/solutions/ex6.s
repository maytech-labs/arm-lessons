// ex6.s - Exercise 04.6: exit with status 0 using the zero register.
//
// Build:  make
// Run:    ./ex6; echo $?
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #5                  // put something non-zero in x0 first...
    mov x0, xzr                 // ...then overwrite it: xzr always reads as 0
    mov x8, #93                 // exit
    svc #0
