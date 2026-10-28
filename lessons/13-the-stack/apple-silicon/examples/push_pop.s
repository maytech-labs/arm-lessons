// push_pop.s - use the stack as a stack: last in, first out (macOS).
//
// C (pseudo):  push(10, 20); push(30, 40);
//              (c, d) = pop(); (a, b) = pop();
//              return a - b + c - d;     // 10 - 20 + 30 - 40 = -20
//
// Build:  make
// Run:    ./push_pop; echo $?
// Exit status (echo $?): 236     (-20 as a byte)

    .global _main
    .text
    .p2align 2

_main:
    mov x1, #10
    mov x2, #20
    mov x3, #30
    mov x4, #40

    stp x1, x2, [sp, #-16]!     // push: sp -= 16, then store x1, x2 at sp
    stp x3, x4, [sp, #-16]!     // push: sp -= 16, then store x3, x4 at sp

    mov x1, #0                  // wipe the registers, to prove the values
    mov x2, #0                  // really come back from memory
    mov x3, #0
    mov x4, #0

    ldp x13, x14, [sp], #16     // pop: load the LAST pair pushed (30, 40), sp += 16
    ldp x11, x12, [sp], #16     // pop: load the first pair (10, 20), sp += 16

    sub x0, x11, x12            // a - b = -10
    add x0, x0, x13             //       + c = 20
    sub x0, x0, x14             //       - d = -20
    mov x16, #1
    svc #0x80
