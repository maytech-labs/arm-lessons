// sum3.s - an assembly function that C code calls (macOS).
//
// C prototype (see sum3_main.c):
//     long sum3(long a, long b, long c);
// C's name "sum3" becomes the symbol "_sum3", so that is what we define.
//
// Build: make sum3        (clang -g -arch arm64 -o sum3 sum3_main.c sum3.s)
// Run:   ./sum3
// Expected output:
//     sum3(1, 2, 3) = 6
//     sum3(100, -50, 7) = 57

    .text
    .global _sum3
    .p2align 2
_sum3:                      // a leaf function: no calls, so no frame needed
    add     x0, x0, x1      // a + b
    add     x0, x0, x2      // + c, returned in x0
    ret
