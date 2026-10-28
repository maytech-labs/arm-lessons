// sum3.s - an assembly function that C code calls.
//
// C prototype (see sum3_main.c):
//     long sum3(long a, long b, long c);
//
// Build: make sum3        (gcc -g -o sum3 sum3_main.c sum3.s)
// Run:   ./sum3
// Expected output:
//     sum3(1, 2, 3) = 6
//     sum3(100, -50, 7) = 57

    .text
    .global sum3            // without .global, the C file could not find it
    .p2align 2
sum3:                       // a leaf function: no calls, so no frame needed
    add     x0, x0, x1      // a + b
    add     x0, x0, x2      // + c, returned in x0
    ret
