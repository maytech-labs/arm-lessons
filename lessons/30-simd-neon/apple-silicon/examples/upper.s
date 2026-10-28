// upper.s - uppercase a string 16 bytes at a time, with vector compares as (macOS)
// masks instead of branches.
//
// For each byte c:  mask = (c - 'a' < 26) ? 0xff : 0x00   (unsigned compare)
//                   c    = c ^ (mask & 0x20)              (clear bit 5 of letters)
//
// Build:  make
// Run:    ./upper
// Expected output:
//   HELLO, SIMD WORLD! 0123456789 ABC XYZ {}

    .global _main

    .data
    .p2align 4
text:
    .asciz "hello, simd world! 0123456789 abc xyz {}"
    .equ LEN, . - text - 1      // not counting the 0

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, text@PAGE
    add x9, x9, text@PAGEOFF
    mov x10, #LEN
    movi v4.16b, #'a'           // 16 copies of 'a'
    movi v5.16b, #26            // 16 copies of 26
    movi v6.16b, #0x20          // 16 copies of the case bit

vector_loop:
    cmp x10, #16
    b.lo tail_loop
    ld1 {v0.16b}, [x9]          // 16 characters
    sub v1.16b, v0.16b, v4.16b  // c - 'a' (wraps for c < 'a': becomes large)
    cmhi v2.16b, v5.16b, v1.16b // 26 > c - 'a' ?  0xff : 0x00, per byte
    and v2.16b, v2.16b, v6.16b  // 0x20 where it is a lowercase letter
    eor v0.16b, v0.16b, v2.16b  // flip bit 5 there
    st1 {v0.16b}, [x9], #16
    sub x10, x10, #16
    b vector_loop

tail_loop:                      // the last 0-15 characters, one at a time
    cbz x10, done
    ldrb w11, [x9]
    sub w12, w11, #'a'
    cmp w12, #26
    b.hs 1f
    eor w11, w11, #0x20
    strb w11, [x9]
1:  add x9, x9, #1
    sub x10, x10, #1
    b tail_loop

done:
    adrp x0, text@PAGE
    add x0, x0, text@PAGEOFF
    bl _puts
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
