// lanes.s - one 128-bit register, many lanes: four ints added at once (macOS).
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

    .global _main

    .data
    .p2align 4
a:  .word 1, 2, 3, 4
b:  .word 10, 20, 30, 40

    .section __TEXT,__const
fmt1:   .asciz "{1 2 3 4} + {10 20 30 40} = {%d %d %d %d}\n"
fmt2:   .asciz "the same 16 bytes as 8 halfwords: %d %d %d %d %d %d %d %d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]           // v8 (its low 64 bits, d8) is callee-saved

    adrp x0, a@PAGE
    add x0, x0, a@PAGEOFF
    ld1 {v0.4s}, [x0]           // v0 = a[0..3]: 4 lanes of 32 bits
    adrp x0, b@PAGE
    add x0, x0, b@PAGEOFF
    ld1 {v1.4s}, [x0]           // v1 = b[0..3]
    add v8.4s, v0.4s, v1.4s     // FOUR additions, one instruction

    mov w1, v8.s[0]             // copy single lanes out to general registers
    mov w2, v8.s[1]
    mov w3, v8.s[2]
    mov w4, v8.s[3]
    adrp x0, fmt1@PAGE
    add x0, x0, fmt1@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    str x4, [sp, #24]
    bl _printf
    add sp, sp, #32

    sub sp, sp, #64             // macOS: all 8 variadic arguments go on the stack
    umov w9, v8.h[0]            // read the same register as 16-bit lanes
    str x9, [sp, #0]
    umov w9, v8.h[1]
    str x9, [sp, #8]
    umov w9, v8.h[2]
    str x9, [sp, #16]
    umov w9, v8.h[3]
    str x9, [sp, #24]
    umov w9, v8.h[4]
    str x9, [sp, #32]
    umov w9, v8.h[5]
    str x9, [sp, #40]
    umov w9, v8.h[6]
    str x9, [sp, #48]
    umov w9, v8.h[7]
    str x9, [sp, #56]
    adrp x0, fmt2@PAGE
    add x0, x0, fmt2@PAGEOFF
    bl _printf
    add sp, sp, #64

    mov w0, #0
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
