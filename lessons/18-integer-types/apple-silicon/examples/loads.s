// loads.s - the same bytes read as different C types (macOS).
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

    .global _main

    .data
bytes:
    .quad -1                    // eight 0xff bytes

    .section __TEXT,__const
fmt1:   .asciz "unsigned char %ld, signed char %ld\n"
fmt2:   .asciz "unsigned short %ld, short %ld\n"
fmt3:   .asciz "unsigned int %ld, int %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    adrp x19, bytes@PAGE
    add x19, x19, bytes@PAGEOFF

    ldrb w1, [x19]              // zero-extend 1 byte: 255
    ldrsb x2, [x19]             // sign-extend 1 byte to 64 bits: -1
    adrp x0, fmt1@PAGE
    add x0, x0, fmt1@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    ldrh w1, [x19]              // zero-extend 2 bytes
    ldrsh x2, [x19]             // sign-extend 2 bytes
    adrp x0, fmt2@PAGE
    add x0, x0, fmt2@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    ldr w1, [x19]               // 4 bytes; writing w1 zeroes the top of x1
    ldrsw x2, [x19]             // 4 bytes, sign-extended
    adrp x0, fmt3@PAGE
    add x0, x0, fmt3@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
