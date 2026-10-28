// static_local.s - a C static local: one variable that keeps its value (macOS)
// between calls, but that no other file can see.
//
// C:      long next_ticket(void) {
//             static long n = 100;         // initialised once, lives in .data
//             return n++;
//         }
//         printf("%ld %ld %ld\n", next_ticket(), next_ticket(), next_ticket());
//
// Build:  make
// Run:    ./static_local
// Look:   nm static_local | grep next_ticket_n      (a lowercase d: local data)
// Expected output:
//   100 101 102

    .global _main

    .data
    .p2align 3
next_ticket_n:                  // no .global: local to this file, like C static
    .quad 100

    .section __TEXT,__const
fmt:
    .asciz "%ld %ld %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    bl next_ticket
    mov x19, x0
    bl next_ticket
    mov x20, x0
    bl next_ticket
    mov x3, x0
    mov x1, x19
    mov x2, x20
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// long next_ticket(void)
next_ticket:
    adrp x9, next_ticket_n@PAGE
    add x9, x9, next_ticket_n@PAGEOFF
    ldr x0, [x9]                // return the old value...
    add x10, x0, #1
    str x10, [x9]               // ...and store n + 1 for next time
    ret
