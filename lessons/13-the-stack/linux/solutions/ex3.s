// ex3.s - Exercise 13.3: swap x1 and x2 through the stack.
//
// Build:  make
// Run:    ./ex3; echo $?
// Exit status (echo $?): 73     (after the swap, x1 = 7 and x2 = 3: 7 * 10 + 3)

    .global _start
    .text
    .p2align 2

_start:
    mov x1, #3
    mov x2, #7
    stp x1, x2, [sp, #-16]!     // push x1 (at sp) and x2 (at sp + 8)
    ldp x2, x1, [sp], #16       // pop them back into the OTHER registers
    mov x3, #10
    madd x0, x1, x3, x2         // x0 = x1 * 10 + x2 = 73
    mov x8, #93
    svc #0
