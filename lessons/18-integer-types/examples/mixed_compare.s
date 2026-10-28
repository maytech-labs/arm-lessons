// mixed_compare.s - comparing signed with unsigned: C converts to unsigned.
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

    .global main

    .section .rodata
fmt:    .asciz "signed: %d, mixed int/unsigned: %d, mixed long/unsigned: %d\n"

    .text
    .p2align 2
main:
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

    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
