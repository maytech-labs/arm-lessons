// union.s - a union: several types sharing the same bytes (macOS).
//
// C:      union word { unsigned int u; unsigned short h[2]; unsigned char b[4]; };
//         union word w;  w.u = 0x11223344;
//         printf("%x: halves %x %x, bytes %x %x %x %x\n",
//                w.u, w.h[0], w.h[1], w.b[0], w.b[1], w.b[2], w.b[3]);
//
// Build:  make
// Run:    ./union
// Expected output:
//   11223344: halves 3344 1122, bytes 44 33 22 11

    .global _main

    .bss
    .p2align 2
w:  .space 4                    // sizeof(union word) = its largest member

    .section __TEXT,__const
fmt:    .asciz "%x: halves %x %x, bytes %x %x %x %x\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, w@PAGE
    add x9, x9, w@PAGEOFF
    movz w10, #0x3344
    movk w10, #0x1122, lsl #16
    str w10, [x9]               // w.u = 0x11223344

    ldr w1, [x9]                // w.u        (every member starts at offset 0)
    ldrh w2, [x9]               // w.h[0]
    ldrh w3, [x9, #2]           // w.h[1]
    ldrb w4, [x9]               // w.b[0]
    ldrb w5, [x9, #1]
    ldrb w6, [x9, #2]
    ldrb w7, [x9, #3]
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #64             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    str x4, [sp, #24]
    str x5, [sp, #32]
    str x6, [sp, #40]
    str x7, [sp, #48]
    bl _printf
    add sp, sp, #64

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
