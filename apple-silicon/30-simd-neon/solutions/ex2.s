// ex2.s - Exercise 30.2: dot product of two int arrays with mla and addv (macOS).
//
// C:      int a[20] = {1..20}, b[20] = {1..20};
//         long dot = 0;  for (i = 0; i < 20; i++) dot += a[i] * b[i];
//
// Build:  make
// Run:    ./ex2
// Expected output:
//   dot = 2870

    .global _main

    .data
    .p2align 4
a:  .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
    .equ N, (. - a) / 4
b:  .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20

    .section __TEXT,__const
fmt:    .asciz "dot = %d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF
    adrp x10, b@PAGE
    add x10, x10, b@PAGEOFF
    mov x11, #N
    movi v0.4s, #0              // four partial sums
vector_loop:
    cmp x11, #4
    b.lo reduce
    ld1 {v1.4s}, [x9], #16
    ld1 {v2.4s}, [x10], #16
    mla v0.4s, v1.4s, v2.4s     // v0 += v1 * v2, lane by lane
    sub x11, x11, #4
    b vector_loop
reduce:
    addv s0, v0.4s
    fmov w1, s0
tail_loop:                      // 20 is a multiple of 4: this loop runs 0 times
    cbz x11, done
    ldr w12, [x9], #4
    ldr w13, [x10], #4
    madd w1, w12, w13, w1
    sub x11, x11, #1
    b tail_loop
done:
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    bl _printf
    add sp, sp, #16
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
