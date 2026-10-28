// pairs.s - ldp/stp move two registers at once: copy a 16-byte record.
//
// Build:  make
// Run:    ./pairs; echo $?
// Expect: exit status 42 (7 * 6, both read from the copy)
//
// C equivalent:
//     long src[2] = {7, 6};
//     long dst[2];
//     dst[0] = src[0]; dst[1] = src[1];
//     return dst[0] * dst[1];

    .global _main

    .data
    .p2align 3
src:    .quad 7, 6
dst:    .quad 0, 0

    .text
    .p2align 2

_main:
    adrp x0, src@PAGE
    add x0, x0, src@PAGEOFF     // x0 = &src[0]
    adrp x1, dst@PAGE
    add x1, x1, dst@PAGEOFF     // x1 = &dst[0]

    ldp x2, x3, [x0]            // x2 = src[0] (at x0), x3 = src[1] (at x0 + 8)
    stp x2, x3, [x1]            // dst[0] = x2, dst[1] = x3

    mov x2, #0                  // wipe the registers...
    mov x3, #0
    ldp x4, x5, [x1]            // ...and read the copy back
    mul x0, x4, x5              // 7 * 6
    mov x16, #1                 // 1 = exit
    svc #0x80
