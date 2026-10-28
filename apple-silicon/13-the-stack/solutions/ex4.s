// ex4.s - Exercise 13.4: print three numbers, each with its own stack buffer (macOS)
// that is allocated before and freed after it is printed.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   7 365 1000000
// Exit status (echo $?): 0
//
// The same block is repeated three times; lesson 14 turns it into a function.
// Each copy: sub sp, convert x19 into the buffer, write, add sp.

    .global _main
    .text
    .p2align 2

_main:
    mov x19, #7
    mov w20, #' '
    sub sp, sp, #32             // ---- buffer for this number
    add x5, sp, #32
    mov x1, x5
    strb w20, [x1, #-1]!        // separator last
    mov x3, #10
digit1:
    udiv x4, x19, x3
    msub x6, x4, x3, x19
    add w6, w6, #'0'
    strb w6, [x1, #-1]!
    mov x19, x4
    cbnz x19, digit1
    mov x0, #1
    sub x2, x5, x1
    mov x16, #4
    svc #0x80
    add sp, sp, #32             // ---- buffer freed

    mov x19, #365
    mov w20, #' '
    sub sp, sp, #32
    add x5, sp, #32
    mov x1, x5
    strb w20, [x1, #-1]!
    mov x3, #10
digit2:
    udiv x4, x19, x3
    msub x6, x4, x3, x19
    add w6, w6, #'0'
    strb w6, [x1, #-1]!
    mov x19, x4
    cbnz x19, digit2
    mov x0, #1
    sub x2, x5, x1
    mov x16, #4
    svc #0x80
    add sp, sp, #32

    movz x19, #0x4240           // 1000000 = 0xf4240
    movk x19, #0xf, lsl #16
    mov w20, #'\n'
    sub sp, sp, #32
    add x5, sp, #32
    mov x1, x5
    strb w20, [x1, #-1]!
    mov x3, #10
digit3:
    udiv x4, x19, x3
    msub x6, x4, x3, x19
    add w6, w6, #'0'
    strb w6, [x1, #-1]!
    mov x19, x4
    cbnz x19, digit3
    mov x0, #1
    sub x2, x5, x1
    mov x16, #4
    svc #0x80
    add sp, sp, #32

    mov x0, #0
    mov x16, #1
    svc #0x80
