// stats.s - mean and standard deviation of an array of doubles (lesson 23, macOS)
//
// Build: make stats
// Run:   ./stats
// Expected output:
//   n      = 8
//   mean   = 5.000000
//   stddev = 2.000000

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16

    mov x1, #8                  // printf("n      = %ld\n", 8L)
    str x1, [sp]
    adrp x0, f_n@PAGE
    add x0, x0, f_n@PAGEOFF
    bl _printf

    adrp x0, data@PAGE
    add x0, x0, data@PAGEOFF
    mov x1, #8
    bl mean                     // d0 = mean(data, 8)
    str d0, [sp]
    adrp x0, f_mean@PAGE
    add x0, x0, f_mean@PAGEOFF
    bl _printf

    adrp x0, data@PAGE
    add x0, x0, data@PAGEOFF
    mov x1, #8
    bl stddev                   // d0 = stddev(data, 8)
    str d0, [sp]
    adrp x0, f_sd@PAGE
    add x0, x0, f_sd@PAGEOFF
    bl _printf

    mov w0, #0
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

// double mean(const double *a, long n)       (leaf)
//     double sum = 0; for (i = 0; i < n; i++) sum += a[i]; return sum / n;
mean:
    fmov d0, xzr                // sum = 0.0
    mov x2, #0                  // i = 0
mean_loop:
    cmp x2, x1
    b.ge mean_done
    ldr d1, [x0, x2, lsl #3]    // a[i]: 8-byte elements, scale by 8
    fadd d0, d0, d1
    add x2, x2, #1
    b mean_loop
mean_done:
    scvtf d1, x1                // (double)n
    fdiv d0, d0, d1
    ret

// double stddev(const double *a, long n)
//     double m = mean(a, n), sum = 0;
//     for (i = 0; i < n; i++) { double d = a[i] - m; sum += d * d; }
//     return sqrt(sum / n);
stddev:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // keep a and n across the call
    mov x20, x1
    bl mean                     // d0 = m (x0, x1 may be clobbered)
    fmov d2, d0                 // d2 = m
    fmov d0, xzr                // sum = 0.0
    mov x2, #0
stddev_loop:
    cmp x2, x20
    b.ge stddev_done
    ldr d1, [x19, x2, lsl #3]   // a[i]
    fsub d1, d1, d2             // d = a[i] - m
    fmadd d0, d1, d1, d0        // sum += d * d
    add x2, x2, #1
    b stddev_loop
stddev_done:
    scvtf d1, x20
    fdiv d0, d0, d1             // variance = sum / n
    fsqrt d0, d0                // standard deviation
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__const
    .p2align 3
data:
    .double 2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0

    .section __TEXT,__cstring
f_n:    .asciz "n      = %ld\n"
f_mean: .asciz "mean   = %f\n"
f_sd:   .asciz "stddev = %f\n"
