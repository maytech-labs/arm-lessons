// ex1.s - Exercise 04.1: exit with your own choice of status (here, 25).
//
// Build:  make
// Run:    ./ex1; echo $?
// Exit status (echo $?): 25

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #25                 // pick any number 0-255
    mov x8, #93                 // exit
    svc #0
