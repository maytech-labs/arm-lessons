// ex5.s - Exercise 30.5: de-interleave RGB pixels with ld3.
//
// 16 pixels stored as R G B R G B ... (48 bytes). ld3 puts all 16 reds in
// v0, all greens in v1, all blues in v2. uaddlv adds 16 bytes into a halfword
// (sums up to 16 * 255 = 4080 need more than 8 bits).
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   red 2040, green 1016, blue 120

    .global main

    .data
    .p2align 4
pixels:
    .rept 16
    .byte 127, 63, 7            // the same pixel 16 times... except one below
    .endr

    .section .rodata
fmt:    .asciz "red %d, green %d, blue %d\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, pixels
    add x9, x9, :lo12:pixels
    mov w10, #135
    strb w10, [x9]              // make pixel 0's red 135 instead of 127
    mov w10, #71
    strb w10, [x9, #1]          // and its green 71
    mov w10, #15
    strb w10, [x9, #2]          // and its blue 15

    ld3 {v0.16b, v1.16b, v2.16b}, [x9]  // de-interleave 48 bytes
    uaddlv h0, v0.16b           // sum of the 16 reds, widened to 16 bits
    uaddlv h1, v1.16b
    uaddlv h2, v2.16b
    umov w1, v0.h[0]
    umov w2, v1.h[0]
    umov w3, v2.h[0]
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
