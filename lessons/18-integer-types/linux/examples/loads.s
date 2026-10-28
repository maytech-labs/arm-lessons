// loads.s - the same bytes read as different C types.
//
// The bytes ff ff ff ff ff ff ff ff, read as each type:
//
// C:      unsigned char  uc = *(unsigned char  *)p;   // ldrb   ->  255
//         signed char    sc = *(signed char    *)p;   // ldrsb  ->  -1
//         unsigned short us = *(unsigned short *)p;   // ldrh   ->  65535
//         short          ss = *(short          *)p;   // ldrsh  ->  -1
//         unsigned int   ui = *(unsigned int   *)p;   // ldr w  ->  4294967295
//         int            si = *(int            *)p;   // ldrsw  ->  -1
//
// Build:  make
// Run:    ./loads
// Expected output:
//   unsigned char 255, signed char -1
//   unsigned short 65535, short -1
//   unsigned int 4294967295, int -1

    .global main

    .data
bytes:
    .quad -1                    // eight 0xff bytes

    .section .rodata
fmt1:   .asciz "unsigned char %ld, signed char %ld\n"
fmt2:   .asciz "unsigned short %ld, short %ld\n"
fmt3:   .asciz "unsigned int %ld, int %ld\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    adrp x19, bytes
    add x19, x19, :lo12:bytes

    ldrb w1, [x19]              // zero-extend 1 byte: 255
    ldrsb x2, [x19]             // sign-extend 1 byte to 64 bits: -1
    adrp x0, fmt1
    add x0, x0, :lo12:fmt1
    bl printf

    ldrh w1, [x19]              // zero-extend 2 bytes
    ldrsh x2, [x19]             // sign-extend 2 bytes
    adrp x0, fmt2
    add x0, x0, :lo12:fmt2
    bl printf

    ldr w1, [x19]               // 4 bytes; writing w1 zeroes the top of x1
    ldrsw x2, [x19]             // 4 bytes, sign-extended
    adrp x0, fmt3
    add x0, x0, :lo12:fmt3
    bl printf

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
