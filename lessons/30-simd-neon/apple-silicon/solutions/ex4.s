// ex4.s - Exercise 30.4: copy 100 bytes, 16 at a time plus a byte tail, (macOS)
// and check the copy with memcmp.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   copied 100 bytes: ok

    .global _main
    .equ SIZE, 100

    .bss
    .p2align 4
src:    .space SIZE
dst:    .space SIZE

    .section __TEXT,__const
fmt:    .asciz "copied %d bytes: %s\n"
ok:     .asciz "ok"
bad:    .asciz "MISMATCH"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, src@PAGE           // fill src with 0, 1, 2, ..., 99
    add x9, x9, src@PAGEOFF
    mov w10, #0
1:  strb w10, [x9, x10]
    add w10, w10, #1
    cmp w10, #SIZE
    b.lo 1b

    adrp x0, dst@PAGE           // my_memcpy(dst, src, SIZE)
    add x0, x0, dst@PAGEOFF
    adrp x1, src@PAGE
    add x1, x1, src@PAGEOFF
    mov x2, #SIZE
    bl my_memcpy

    adrp x0, dst@PAGE           // memcmp(dst, src, SIZE) == 0 ?
    add x0, x0, dst@PAGEOFF
    adrp x1, src@PAGE
    add x1, x1, src@PAGEOFF
    mov x2, #SIZE
    bl _memcmp
    adrp x2, ok@PAGE
    add x2, x2, ok@PAGEOFF
    adrp x9, bad@PAGE
    add x9, x9, bad@PAGEOFF
    cmp w0, #0
    csel x2, x2, x9, eq
    mov w1, #SIZE
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// void my_memcpy(void *dst, const void *src, size_t n): leaf
my_memcpy:
    cmp x2, #16
    b.lo 2f
    ld1 {v0.16b}, [x1], #16     // 16 bytes in one load...
    st1 {v0.16b}, [x0], #16     // ...and one store
    sub x2, x2, #16
    b my_memcpy
2:  cbz x2, 3f                  // the last 0-15 bytes
    ldrb w9, [x1], #1
    strb w9, [x0], #1
    sub x2, x2, #1
    b 2b
3:  ret
