// ex4.s - Exercise 30.4: copy 100 bytes, 16 at a time plus a byte tail,
// and check the copy with memcmp.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   copied 100 bytes: ok

    .global main
    .equ SIZE, 100

    .bss
    .p2align 4
src:    .space SIZE
dst:    .space SIZE

    .section .rodata
fmt:    .asciz "copied %d bytes: %s\n"
ok:     .asciz "ok"
bad:    .asciz "MISMATCH"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, src                // fill src with 0, 1, 2, ..., 99
    add x9, x9, :lo12:src
    mov w10, #0
1:  strb w10, [x9, x10]
    add w10, w10, #1
    cmp w10, #SIZE
    b.lo 1b

    adrp x0, dst                // my_memcpy(dst, src, SIZE)
    add x0, x0, :lo12:dst
    adrp x1, src
    add x1, x1, :lo12:src
    mov x2, #SIZE
    bl my_memcpy

    adrp x0, dst                // memcmp(dst, src, SIZE) == 0 ?
    add x0, x0, :lo12:dst
    adrp x1, src
    add x1, x1, :lo12:src
    mov x2, #SIZE
    bl memcmp
    adrp x2, ok
    add x2, x2, :lo12:ok
    adrp x9, bad
    add x9, x9, :lo12:bad
    cmp w0, #0
    csel x2, x2, x9, eq
    mov w1, #SIZE
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

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
