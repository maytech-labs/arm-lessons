// sum3_main.c - C code that calls the assembly function in sum3.s.
// Build: make sum3

#include <stdio.h>

long sum3(long a, long b, long c);   // the prototype: tells C how to call it

int main(void) {
    printf("sum3(1, 2, 3) = %ld\n", sum3(1, 2, 3));
    printf("sum3(100, -50, 7) = %ld\n", sum3(100, -50, 7));
    return 0;
}
