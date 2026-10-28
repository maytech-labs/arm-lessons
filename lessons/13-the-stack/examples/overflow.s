// overflow.s - a broken program: it pushes forever and runs off the end of
// the stack. This is a "stack overflow".
//
// Build:  make
// Run:    ./overflow; echo $?
// Exit status (echo $?): 139, after "Segmentation fault" (SIGSEGV = signal 11)

    .global _start
    .text
    .p2align 2

_start:
    mov x1, #0
again:
    stp x1, x1, [sp, #-16]!     // push 16 bytes, forever
    add x1, x1, #1
    b again                     // after about 8 MiB the stack is full
