// lanes.s - one 128-bit register, many lanes: four ints added at once.
//
// C (with arm_neon.h):
//         int a[4] = {1, 2, 3, 4}, b[4] = {10, 20, 30, 40}, c[4];
//         vst1q_s32(c, vaddq_s32(vld1q_s32(a), vld1q_s32(b)));
//
// Build:  make
// Run:    ./lanes
// Expected output:
//   {1 2 3 4} + {10 20 30 40} = {11 22 33 44}
//   the same 16 bytes as 8 halfwords: 11 0 22 0 33 0 44 0

    .global main

    .data
    .p2align 4
a:  .word 1, 2, 3, 4
b:  .word 10, 20, 30, 40

    .section .rodata
fmt1:   .asciz "{1 2 3 4} + {10 20 30 40} = {%d %d %d %d}\n"
fmt2:   .asciz "the same 16 bytes as 8 halfwords: %d %d %d %d %d %d %d %d\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]           // v8 (its low 64 bits, d8) is callee-saved

    adrp x0, a
    add x0, x0, :lo12:a
    ld1 {v0.4s}, [x0]           // v0 = a[0..3]: 4 lanes of 32 bits
    adrp x0, b
    add x0, x0, :lo12:b
    ld1 {v1.4s}, [x0]           // v1 = b[0..3]
    add v8.4s, v0.4s, v1.4s     // FOUR additions, one instruction

    mov w1, v8.s[0]             // copy single lanes out to general registers
    mov w2, v8.s[1]
    mov w3, v8.s[2]
    mov w4, v8.s[3]
    adrp x0, fmt1
    add x0, x0, :lo12:fmt1
    bl printf

    umov w1, v8.h[0]            // the same register, read as 16-bit lanes
    umov w2, v8.h[1]
    umov w3, v8.h[2]
    umov w4, v8.h[3]
    umov w5, v8.h[4]
    umov w6, v8.h[5]
    umov w7, v8.h[6]
    adrp x0, fmt2
    add x0, x0, :lo12:fmt2
    umov w9, v8.h[7]
    str x9, [sp, #-16]!         // the 9th printf argument goes on the stack
    bl printf
    add sp, sp, #16

    mov w0, #0
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
