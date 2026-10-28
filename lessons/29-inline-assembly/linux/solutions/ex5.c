// ex5.c - Exercise 29.5: the fixed version of a broken asm statement.
//
// The broken version (in the exercise) computes  r = a * 3 + b  as
//     asm("add %0, %1, %1, lsl #1\n\t"     // r = a + 2a
//         "add %0, %0, %2"                 // r += b
//         : "=r"(r) : "r"(a), "r"(b));
// Without "&", the compiler may give r the SAME register as b, because it
// assumes outputs are written only after all inputs are read. The first add
// then destroys b. The early-clobber marker "=&r" forbids that sharing.
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   7 * 3 + 100 = 121
#include <stdio.h>

__attribute__((noinline)) static long times3_plus(long a, long b) {
    long r;
    asm("add %0, %1, %1, lsl #1\n\t"
        "add %0, %0, %2"
        : "=&r"(r)
        : "r"(a), "r"(b));
    return r;
}

int main(void) {
    printf("7 * 3 + 100 = %ld\n", times3_plus(7, 100));
    return 0;
}
