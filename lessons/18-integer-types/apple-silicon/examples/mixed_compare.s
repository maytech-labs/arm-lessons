// mixed_compare.s - comparing signed with unsigned: C converts to unsigned (macOS).
//
// C:      int i = -1;  unsigned u = 1;
//         int r1 = i < (int)u;     // 1: both signed, -1 < 1
//         int r2 = i < u;          // 0: i becomes unsigned 4294967295 > 1
//         long l = -1;
//         int r3 = l < u;          // 1: u becomes long 1; -1 < 1
//
// Build:  make
// Run:    ./mixed_compare
// Expected output:
//   signed: 1, mixed int/unsigned: 0, mixed long/unsigned: 1

    .global _main

    .section __TEXT,__const
fmt:    .asciz "signed: %d, mixed int/unsigned: %d, mixed long/unsigned: %d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov w9, #-1                 // i
    mov w10, #1                 // u
    cmp w9, w10
    cset w1, lt                 // r1: signed condition
    cmp w9, w10
    cset w2, lo                 // r2: unsigned condition (what C chooses here)

    mov x11, #-1                // l
    mov w12, w10                // (long)u: zero-extend, it is unsigned
    cmp x11, x12
    cset w3, lt                 // r3: both are now long: signed condition

    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
