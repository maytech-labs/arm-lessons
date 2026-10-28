// sum_test.c - C test driver for sum.s. The compiler sets up each call,
// so this checks that our hand-written va_arg agrees with the real ABI.
//
// Build and run:
//     make sum
//     ./sum
// Expected output: see the header of sum.s.
#include <stdio.h>

int sum(int n, ...);   // implemented in sum.s

int main(void) {
    printf("sum(0) = %d\n", sum(0));
    printf("sum(3, 10, 20, 30) = %d\n", sum(3, 10, 20, 30));
    printf("sum(7, 1..7) = %d\n", sum(7, 1, 2, 3, 4, 5, 6, 7));
    printf("sum(10, 1..10) = %d\n", sum(10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
    printf("sum(4, -5, 100, -20, 1) = %d\n", sum(4, -5, 100, -20, 1));
    return 0;
}
