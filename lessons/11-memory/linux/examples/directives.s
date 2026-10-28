// directives.s - .byte, .hword, .word and .quad lay down 1, 2, 4 and 8 bytes.
//
// Build:  make
// Run:    ./directives; echo $?
// Expect: exit status 100 (10 + 20 + 30 + 40)

    .global _start

    .data
    .p2align 3
q:  .quad 40                    // 8 bytes  (C: long  q = 40;)
w:  .word 30                    // 4 bytes  (C: int   w = 30;)
h:  .hword 20                   // 2 bytes  (C: short h = 20;)
b:  .byte 10                    // 1 byte   (C: char  b = 10;)

    .text
    .p2align 2

_start:
    adrp x9, q
    add x9, x9, :lo12:q
    ldr x0, [x9]                // x0 = q (8 bytes)

    adrp x9, w
    add x9, x9, :lo12:w
    ldr w1, [x9]                // x1 = w (4 bytes)

    adrp x9, h
    add x9, x9, :lo12:h
    ldrh w2, [x9]               // x2 = h (2 bytes)

    adrp x9, b
    add x9, x9, :lo12:b
    ldrb w3, [x9]               // x3 = b (1 byte)

    add x0, x0, x1              // 40 + 30
    add x0, x0, x2              // + 20
    add x0, x0, x3              // + 10 = 100
    mov x8, #93                 // 93 = exit
    svc #0
