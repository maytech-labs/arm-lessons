// ex1.s - Exercise 04.1: exit with your own choice of status (here, 25) (macOS).
//
// Build:  make
// Run:    ./ex1; echo $?
// Exit status (echo $?): 25

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #25                 // pick any number 0-255
    mov x16, #1                 // exit
    svc #0x80
