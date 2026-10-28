// exit42.s - the smallest useful program: it ends with exit status 42 (macOS).
//
// Build:  make
// Run:    ./exit42; echo $?
// Exit status (echo $?): 42

    .global _main               // make the name _main visible to the linker
    .text                       // what follows is code
    .p2align 2                  // start on a 4-byte boundary (2^2)

_main:                          // the program begins here
    mov x0, #42                 // x0 = 42: the exit status we want
    mov x16, #1                 // x16 = 1: macOS's number for the exit system call
    svc #0x80                   // ask the kernel to run system call x16 with argument x0
