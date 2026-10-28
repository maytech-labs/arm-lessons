// bench.s - a hand-written sum of squares, timed against the compiler's
// version by bench_main.c (macOS version).
//
// This file has no _main; it is linked with bench_main.c.
// Build: make            (the Makefile has an explicit rule for bench)
// Run:   ./bench
// Expected output: both sums are 332833500000. The times change from run
// to run and machine to machine, for example:
//     asm:     sum = 332833500000   time = 0.062 s
//     C -O2:   sum = 332833500000   time = 0.012 s

    .text

// long sum_squares_asm(const int *a, long n)
// A leaf function: no calls, so no frame and only scratch registers.
    .global _sum_squares_asm
    .p2align 2
_sum_squares_asm:
    mov x2, #0                  // s = 0
    cbz x1, 2f                  // n == 0: nothing to do
    add x3, x0, x1, lsl #2      // end = a + n
1:
    ldrsw x4, [x0], #4          // x4 = *a++ (sign-extended to long)
    madd x2, x4, x4, x2         // s += x4 * x4
    cmp x0, x3
    b.ne 1b                     // loop until a == end
2:
    mov x0, x2
    ret
