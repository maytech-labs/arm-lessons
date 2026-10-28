// directives.s - .byte, .hword, .word and .quad lay down 1, 2, 4 and 8 bytes.
//
// Build:  make
// Run:    ./directives; echo $?
// Expect: exit status 100 (10 + 20 + 30 + 40)

    .global _main

    .data
    .p2align 3
q:  .quad 40                    // 8 bytes  (C: long  q = 40;)
w:  .word 30                    // 4 bytes  (C: int   w = 30;)
h:  .hword 20                   // 2 bytes  (C: short h = 20;)
b:  .byte 10                    // 1 byte   (C: char  b = 10;)

    .text
    .p2align 2

_main:
    adrp x9, q@PAGE
    add x9, x9, q@PAGEOFF
    ldr x0, [x9]                // x0 = q (8 bytes)

    adrp x9, w@PAGE
    add x9, x9, w@PAGEOFF
    ldr w1, [x9]                // x1 = w (4 bytes)

    adrp x9, h@PAGE
    add x9, x9, h@PAGEOFF
    ldrh w2, [x9]               // x2 = h (2 bytes)

    adrp x9, b@PAGE
    add x9, x9, b@PAGEOFF
    ldrb w3, [x9]               // x3 = b (1 byte)

    add x0, x0, x1              // 40 + 30
    add x0, x0, x2              // + 20
    add x0, x0, x3              // + 10 = 100
    mov x16, #1                 // 1 = exit
    svc #0x80
