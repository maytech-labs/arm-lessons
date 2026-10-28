// promote.s - integer promotion: small types are computed as int.
//
// C:      unsigned char a = 200, b = 100;
//         int           s = a + b;        // 300: a and b are promoted to int first
//         unsigned char c = a + b;        // 44:  300 truncated back to 8 bits
//         unsigned int  x = 4000000000u, y = 1000000000u;
//         unsigned int  z = x + y;        // 705032704: wraps at 2^32
//         long          w = (long)x + y;  // 5000000000: computed in 64 bits
//
// Build:  make
// Run:    ./promote
// Expected output:
//   int s = 300, unsigned char c = 44
//   unsigned z = 705032704, long w = 5000000000

    .global main

    .section .rodata
fmt1:   .asciz "int s = %d, unsigned char c = %d\n"
fmt2:   .asciz "unsigned z = %u, long w = %ld\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov w9, #200                // a
    mov w10, #100               // b
    add w1, w9, w10             // s = a + b, computed in 32 bits: 300
    and w2, w1, #0xff           // c = (unsigned char)(a + b): keep 8 bits
    adrp x0, fmt1
    add x0, x0, :lo12:fmt1
    bl printf

    movz w9, #0x2800            // x = 4000000000 = 0xee6b2800
    movk w9, #0xee6b, lsl #16
    movz w10, #0xca00           // y = 1000000000 = 0x3b9aca00
    movk w10, #0x3b9a, lsl #16
    add w1, w9, w10             // z = x + y in 32 bits: wraps
    add x2, x9, x10             // w: the same registers as 64-bit values
                                //   (writing w9/w10 zeroed their top halves)
    adrp x0, fmt2
    add x0, x0, :lo12:fmt2
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
