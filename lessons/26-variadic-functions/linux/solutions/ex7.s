// ex7.s - exercise 26.7: double average(int n, ...) of n doubles,
// using the FP/SIMD half of the va_list.
//
// The C version:
//     double average(int n, ...) {
//         if (n == 0) return 0.0;
//         va_list ap;
//         va_start(ap, n);
//         double total = 0.0;
//         for (int i = 0; i < n; i++) total += va_arg(ap, double);
//         va_end(ap);
//         return total / n;
//     }
//
// Build and run:
//     make ex7
//     ./ex7
// Expected output:
//     average of 1.5 2.5 3.5 4.5 = 3.000000
//     average of 1..10 = 5.500000
//     average of nothing = 0.000000

    .equ VA_STACK,    0
    .equ VA_GR_TOP,   8
    .equ VA_VR_TOP,  16
    .equ VA_GR_OFFS, 24
    .equ VA_VR_OFFS, 28

// Frame of average (176 bytes):
//     sp+0    x29, x30
//     sp+16   va_list ap            (32 bytes)
//     sp+48   q0 .. q7              (VR save area, 128 bytes, ends at sp+176)
//     sp+176  = entry sp
// We never read an integer from "...", so there is no GR save area.
    .equ AP,        16
    .equ VR_SAVE,   48
    .equ VR_TOP,   176
    .equ FRAME,    176

    .text
    .global average
    .p2align 2
average:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    stp     q0, q1, [sp, #VR_SAVE]
    stp     q2, q3, [sp, #VR_SAVE + 32]
    stp     q4, q5, [sp, #VR_SAVE + 64]
    stp     q6, q7, [sp, #VR_SAVE + 96]

    // va_start(ap, n): no named FP arguments, so all eight q slots count.
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]
    str     xzr, [sp, #AP + VA_GR_TOP]      // unused: __gr_offs = 0
    add     x9, sp, #VR_TOP
    str     x9, [sp, #AP + VA_VR_TOP]
    str     wzr, [sp, #AP + VA_GR_OFFS]
    mov     w9, #-128                       // -(8 - 0) * 16
    str     w9, [sp, #AP + VA_VR_OFFS]

    movi    d0, #0                          // result 0.0 if n == 0
    cbz     w0, done
    movi    d16, #0                         // d16 = total
    mov     w10, w0                         // w10 = counter
loop:
    cbz     w10, divide
    // va_arg(ap, double) -> address in x14
    ldr     w12, [sp, #AP + VA_VR_OFFS]
    tbz     w12, #31, from_stack
    add     w13, w12, #16                   // q slots are 16 bytes
    str     w13, [sp, #AP + VA_VR_OFFS]
    ldr     x14, [sp, #AP + VA_VR_TOP]
    add     x14, x14, w12, sxtw
    b       have_addr
from_stack:
    ldr     x14, [sp, #AP + VA_STACK]
    add     x13, x14, #8                    // stack slots are 8 bytes
    str     x13, [sp, #AP + VA_STACK]
have_addr:
    ldr     d17, [x14]                      // the double: low 8 bytes of the slot
    fadd    d16, d16, d17
    sub     w10, w10, #1
    b       loop
divide:
    scvtf   d17, w0
    fdiv    d0, d16, d17
done:
    ldp     x29, x30, [sp], #FRAME
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     w0, #4
    fmov    d0, #1.5
    fmov    d1, #2.5
    fmov    d2, #3.5
    fmov    d3, #4.5
    bl      average
    adrp    x0, f1
    add     x0, x0, :lo12:f1
    bl      printf                          // the result is already in d0

    // Ten doubles: 1.0 .. 8.0 in d0-d7, 9.0 and 10.0 on the stack.
    sub     sp, sp, #16
    fmov    d16, #9.0
    fmov    d17, #10.0
    stp     d16, d17, [sp]
    mov     w0, #10
    fmov    d0, #1.0
    fmov    d1, #2.0
    fmov    d2, #3.0
    fmov    d3, #4.0
    fmov    d4, #5.0
    fmov    d5, #6.0
    fmov    d6, #7.0
    fmov    d7, #8.0
    bl      average
    add     sp, sp, #16
    adrp    x0, f2
    add     x0, x0, :lo12:f2
    bl      printf

    mov     w0, #0
    bl      average
    adrp    x0, f3
    add     x0, x0, :lo12:f3
    bl      printf

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
f1: .asciz  "average of 1.5 2.5 3.5 4.5 = %f\n"
f2: .asciz  "average of 1..10 = %f\n"
f3: .asciz  "average of nothing = %f\n"
