// exit42.s - the smallest useful program: it ends with exit status 42.
//
// Build:  make
// Run:    ./exit42; echo $?
// Exit status (echo $?): 42

    .global _start              // make the name _start visible to the linker
    .text                       // what follows is code
    .p2align 2                  // start on a 4-byte boundary (2^2)

_start:                         // the program begins here
    mov x0, #42                 // x0 = 42: the exit status we want
    mov x8, #93                 // x8 = 93: Linux's number for the exit system call
    svc #0                      // ask the kernel to run system call x8 with argument x0
