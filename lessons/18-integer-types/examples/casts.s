// casts.s - C casts between integer types are truncations and extensions.
//
// C:      long  big  = 0x123456789;        // needs 33 bits
//         int   t    = (int)big;           // truncate:      0x23456789
//         int   neg  = -5;
//         long  sx   = neg;                // sign-extend:   -5
//         long  zx   = (unsigned)neg;      // zero-extend:   4294967291
//         char  c    = (char)300;          // truncate to 8 bits: 44
//         short h    = (short)0x18000;     // truncate to 16 bits, signed: -32768
//
// Build:  make
// Run:    ./casts
// Expected output:
//   (int)0x123456789 = 0x23456789
//   (long)-5 = -5, (long)(unsigned)-5 = 4294967291
//   (char)300 = 44, (short)0x18000 = -32768

    .global main

    .section .rodata
fmt1:   .asciz "(int)0x123456789 = 0x%x\n"
fmt2:   .asciz "(long)-5 = %ld, (long)(unsigned)-5 = %lu\n"
fmt3:   .asciz "(char)300 = %d, (short)0x18000 = %d\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    movz x9, #0x6789            // big = 0x123456789
    movk x9, #0x2345, lsl #16
    movk x9, #0x1, lsl #32
    mov w1, w9                  // (int)big: just use the low 32 bits
    adrp x0, fmt1
    add x0, x0, :lo12:fmt1
    bl printf

    mov w9, #-5                 // int neg = -5 (0xfffffffb in w9)
    sxtw x1, w9                 // (long)neg: copy bit 31 into bits 32-63
    mov w2, w9                  // (long)(unsigned)neg: writing w2 zero-extends
    adrp x0, fmt2
    add x0, x0, :lo12:fmt2
    bl printf

    mov w9, #300                // 0x12c
    sxtb w1, w9                 // (char)300 -> 0x2c = 44, then sign-extend for %d
    mov w9, #0x8000
    movk w9, #0x1, lsl #16      // 0x18000
    sxth w2, w9                 // (short): low 16 bits 0x8000, sign-extended = -32768
    adrp x0, fmt3
    add x0, x0, :lo12:fmt3
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
