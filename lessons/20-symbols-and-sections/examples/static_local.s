// static_local.s - a C static local: one variable that keeps its value
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

    .global main

    .data
    .p2align 3
next_ticket_n:                  // no .global: local to this file, like C static
    .quad 100

    .section .rodata
fmt:
    .asciz "%ld %ld %ld\n"

    .text
    .p2align 2
main:
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
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// long next_ticket(void)
next_ticket:
    adrp x9, next_ticket_n
    add x9, x9, :lo12:next_ticket_n
    ldr x0, [x9]                // return the old value...
    add x10, x0, #1
    str x10, [x9]               // ...and store n + 1 for next time
    ret
