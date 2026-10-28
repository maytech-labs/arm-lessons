// ex6.s - Exercise 16.6: long max3(long a, long b, long c), called from C.
//
// Build: make ex6        (gcc -g -o ex6 ex6_main.c ex6.s)
// Run:   ./ex6
// Expected output:
//     max3(1, 9, 4) = 9
//     max3(-5, -2, -9) = -2
//     max3(7, 7, 7) = 7

    .text
    .global max3
    .p2align 2
max3:
    cmp     x0, x1
    csel    x0, x0, x1, gt          // x0 = (a > b) ? a : b   (signed)
    cmp     x0, x2
    csel    x0, x0, x2, gt          // x0 = (x0 > c) ? x0 : c
    ret
