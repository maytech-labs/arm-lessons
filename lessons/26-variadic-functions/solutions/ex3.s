// ex3.s - exercise 26.3: int max_of(int n, ...) returns the largest of n ints.
//
// The C version:
//     int max_of(int n, ...) {
//         va_list ap;
//         va_start(ap, n);
//         int best = va_arg(ap, int);
//         for (int i = 1; i < n; i++) {
//             int v = va_arg(ap, int);
//             if (v > best) best = v;
//         }
//         va_end(ap);
//         return best;
//     }
//
// Build and run:
//     make ex3
//     ./ex3
// Expected output:
//     max_of(3, 4, 9, 2) = 9
//     max_of(1, -5) = -5
//     max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5) = 9
//     max_of(5, -10, -20, -3, -40, -50) = -3

    .equ VA_STACK,    0
    .equ VA_GR_TOP,   8
    .equ VA_VR_TOP,  16
    .equ VA_GR_OFFS, 24
    .equ VA_VR_OFFS, 28

// Frame: sp+0 x29/x30, sp+16 va_list, sp+48 x1..x7 (ends sp+104), sp+112 entry sp.
    .equ AP,       16
    .equ GR_SAVE,  48
    .equ GR_TOP,  104
    .equ FRAME,   112

    .text
    .global max_of
    .p2align 2
max_of:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    stp     x1, x2, [sp, #GR_SAVE]
    stp     x3, x4, [sp, #GR_SAVE + 16]
    stp     x5, x6, [sp, #GR_SAVE + 32]
    str     x7, [sp, #GR_SAVE + 48]
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]
    add     x9, sp, #GR_TOP
    str     x9, [sp, #AP + VA_GR_TOP]
    str     xzr, [sp, #AP + VA_VR_TOP]
    mov     w9, #-56
    str     w9, [sp, #AP + VA_GR_OFFS]
    str     wzr, [sp, #AP + VA_VR_OFFS]

    mov     w10, w0                         // w10 = arguments left
    mov     w11, #0x80000000                // best = INT_MIN (any int beats it)
loop:
    cbz     w10, done
    // va_arg(ap, int) -> address in x14
    ldr     w12, [sp, #AP + VA_GR_OFFS]
    tbz     w12, #31, from_stack
    add     w13, w12, #8
    str     w13, [sp, #AP + VA_GR_OFFS]
    ldr     x14, [sp, #AP + VA_GR_TOP]
    add     x14, x14, w12, sxtw
    b       have_addr
from_stack:
    ldr     x14, [sp, #AP + VA_STACK]
    add     x13, x14, #8
    str     x13, [sp, #AP + VA_STACK]
have_addr:
    ldr     w15, [x14]
    cmp     w15, w11
    csel    w11, w15, w11, gt               // if (v > best) best = v
    sub     w10, w10, #1
    b       loop
done:
    mov     w0, w11
    ldp     x29, x30, [sp], #FRAME
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // max_of(3, 4, 9, 2)
    mov     w0, #3
    mov     w1, #4
    mov     w2, #9
    mov     w3, #2
    bl      max_of
    mov     w1, w0
    adrp    x0, f1
    add     x0, x0, :lo12:f1
    bl      printf

    // max_of(1, -5)
    mov     w0, #1
    mov     w1, #-5
    bl      max_of
    mov     w1, w0
    adrp    x0, f2
    add     x0, x0, :lo12:f2
    bl      printf

    // max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5): the last two go on the stack
    sub     sp, sp, #16
    mov     x9, #6
    mov     x10, #5
    stp     x9, x10, [sp]
    mov     w0, #9
    mov     w1, #3
    mov     w2, #1
    mov     w3, #4
    mov     w4, #1
    mov     w5, #5
    mov     w6, #9
    mov     w7, #2
    bl      max_of
    add     sp, sp, #16
    mov     w1, w0
    adrp    x0, f3
    add     x0, x0, :lo12:f3
    bl      printf

    // max_of(5, -10, -20, -3, -40, -50)
    mov     w0, #5
    mov     w1, #-10
    mov     w2, #-20
    mov     w3, #-3
    mov     w4, #-40
    mov     w5, #-50
    bl      max_of
    mov     w1, w0
    adrp    x0, f4
    add     x0, x0, :lo12:f4
    bl      printf

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
f1: .asciz  "max_of(3, 4, 9, 2) = %d\n"
f2: .asciz  "max_of(1, -5) = %d\n"
f3: .asciz  "max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5) = %d\n"
f4: .asciz  "max_of(5, -10, -20, -3, -40, -50) = %d\n"
