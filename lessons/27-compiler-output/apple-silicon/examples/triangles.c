// triangles.c - the C original of triangles.s.
//
// Prints the first 5 triangle numbers and their sum.
// Build: make            (builds triangles_c from this file)
// Run:   ./triangles_c
// Expected output:
//     T(1) = 1
//     T(2) = 3
//     T(3) = 6
//     T(4) = 10
//     T(5) = 15
//     sum = 35
#include <stdio.h>

long print_triangles(int n) {
    long total = 0;
    long t = 0;
    for (int i = 1; i <= n; i++) {
        t += i;
        printf("T(%d) = %ld\n", i, t);
        total += t;
    }
    return total;
}

int main(void) {
    long s = print_triangles(5);
    printf("sum = %ld\n", s);
    return 0;
}
