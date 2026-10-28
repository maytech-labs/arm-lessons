// fixed_return.s - lost_return.s with outer saving and restoring x30 (macOS).
//
// Build:  make
// Run:    ./fixed_return; echo $?
// Exit status (echo $?): 1

    .global _main
    .text
    .p2align 2

_main:
    mov x19, #0
    bl outer
    mov x0, x19                 // exit(counter) = exit(1)
    mov x16, #1
    svc #0x80

outer:
    stp x29, x30, [sp, #-16]!   // prologue: save the frame pointer and return address
    mov x29, sp                 //           x29 = this function's frame
    bl inner                    // free to overwrite x30 now
    add x19, x19, #1
    ldp x29, x30, [sp], #16     // epilogue: restore them...
    ret                         // ...so ret goes back to _main

inner:
    ret
