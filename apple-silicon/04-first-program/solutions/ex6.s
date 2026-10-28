// ex6.s - Exercise 04.6: exit with status 0 using the zero register (macOS).
//
// Build:  make
// Run:    ./ex6; echo $?
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #5                  // put something non-zero in x0 first...
    mov x0, xzr                 // ...then overwrite it: xzr always reads as 0
    mov x16, #1                 // exit
    svc #0x80
