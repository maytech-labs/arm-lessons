// fixed_return.s - lost_return.s with outer saving and restoring x30.
//
// Build:  make
// Run:    ./fixed_return; echo $?
// Exit status (echo $?): 1

    .global _start
    .text
    .p2align 2

_start:
    mov x19, #0
    bl outer
    mov x0, x19                 // exit(counter) = exit(1)
    mov x8, #93
    svc #0

outer:
    stp x29, x30, [sp, #-16]!   // prologue: save the frame pointer and return address
    mov x29, sp                 //           x29 = this function's frame
    bl inner                    // free to overwrite x30 now
    add x19, x19, #1
    ldp x29, x30, [sp], #16     // epilogue: restore them...
    ret                         // ...so ret goes back to _start

inner:
    ret
