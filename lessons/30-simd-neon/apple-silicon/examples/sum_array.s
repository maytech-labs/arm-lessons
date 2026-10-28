// sum_array.s - sum, min, and max of an int array, four lanes at a time, (macOS)
// with a scalar loop for the leftover elements.
//
// C:      int a[19] = {1, 2, ..., 19};   // 19 is NOT a multiple of 4
//         long sum = 0; int mn = a[0], mx = a[0];
//         for (i = 0; i < 19; i++) { sum += a[i]; mn = min(mn, a[i]); mx = max(mx, a[i]); }
//
// Build:  make
// Run:    ./sum_array
// Expected output:
//   sum 190, min 1, max 19

    .global _main

    .data
    .p2align 4
a:  .word 7, 2, 19, 4, 5, 6, 1, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 3
    .equ N, (. - a) / 4

    .section __TEXT,__const
fmt:    .asciz "sum %d, min %d, max %d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF       // p
    mov x10, #N                 // elements left
    movi v0.4s, #0              // four partial sums
    ld1r {v1.4s}, [x9]          // four partial minimums, all = a[0]
    mov v2.16b, v1.16b          // four partial maximums, all = a[0]

vector_loop:                    // while at least 4 elements remain
    cmp x10, #4
    b.lo reduce
    ld1 {v3.4s}, [x9], #16      // the next 4 elements
    add v0.4s, v0.4s, v3.4s
    smin v1.4s, v1.4s, v3.4s
    smax v2.4s, v2.4s, v3.4s
    sub x10, x10, #4
    b vector_loop

reduce:                         // combine the 4 lanes into one value each
    addv s0, v0.4s              // s0 = lane0 + lane1 + lane2 + lane3
    sminv s1, v1.4s
    smaxv s2, v2.4s
    fmov w1, s0                 // move to general registers
    fmov w2, s1
    fmov w3, s2

tail_loop:                      // the 0-3 elements that did not fill a vector
    cbz x10, done
    ldr w11, [x9], #4
    add w1, w1, w11
    cmp w11, w2
    csel w2, w11, w2, lt
    cmp w11, w3
    csel w3, w11, w3, gt
    sub x10, x10, #1
    b tail_loop

done:
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
