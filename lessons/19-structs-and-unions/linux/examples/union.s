// union.s - a union: several types sharing the same bytes.
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

    .global main

    .bss
    .p2align 2
w:  .space 4                    // sizeof(union word) = its largest member

    .section .rodata
fmt:    .asciz "%x: halves %x %x, bytes %x %x %x %x\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, w
    add x9, x9, :lo12:w
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
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
