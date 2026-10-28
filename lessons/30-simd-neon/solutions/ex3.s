// ex3.s - Exercise 30.3: count a character, 16 bytes per step.
//
// cmeq makes 0xff in every lane that matches; ushr #7 turns 0xff into 1;
// addv adds the 16 lanes (at most 16, so a byte is enough).
//
// Build:  make
// Run:    ./ex3
// Expected output:
//   's' appears 9 times

    .global main

    .data
    .p2align 4
text:
    .ascii "she sells sea shells by the sea shore, surely"
    .equ LEN, . - text

    .section .rodata
fmt:    .asciz "'s' appears %d times\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, text
    add x9, x9, :lo12:text
    mov x10, #LEN
    mov w1, #0                  // count
    movi v4.16b, #'s'
vector_loop:
    cmp x10, #16
    b.lo tail_loop
    ld1 {v0.16b}, [x9], #16
    cmeq v1.16b, v0.16b, v4.16b // 0xff where equal
    ushr v1.16b, v1.16b, #7     // 1 where equal
    addv b2, v1.16b             // matches in these 16 bytes
    umov w11, v2.b[0]
    add w1, w1, w11
    sub x10, x10, #16
    b vector_loop
tail_loop:
    cbz x10, done
    ldrb w11, [x9], #1
    cmp w11, #'s'
    cinc w1, w1, eq
    sub x10, x10, #1
    b tail_loop
done:
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
