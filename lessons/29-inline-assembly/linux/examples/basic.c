// basic.c - the shape of an extended asm statement.
//
// Build:  make
// Run:    ./basic
// Expected output:
//   20 + 22 = 42
//   10 * 3 + 12 = 42
#include <stdio.h>

static long add(long a, long b) {
    long r;
    asm("add %0, %1, %2"        // the template: %0, %1, %2 are the operands below
        : "=r"(r)               // outputs:  %0 = r, in any register ("r"), written ("=")
        : "r"(a), "r"(b));      // inputs:   %1 = a, %2 = b, each in some register
    return r;
}

static long madd(long a, long b, long c) {
    long r;
    asm("madd %[res], %[x], %[y], %[z]"   // operands can be named instead of numbered
        : [res] "=r"(r)
        : [x] "r"(a), [y] "r"(b), [z] "r"(c));
    return r;
}

int main(void) {
    printf("20 + 22 = %ld\n", add(20, 22));
    printf("10 * 3 + 12 = %ld\n", madd(10, 3, 12));
    return 0;
}
