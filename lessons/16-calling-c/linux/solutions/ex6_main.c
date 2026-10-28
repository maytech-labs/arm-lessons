// ex6_main.c - Exercise 16.6: calls max3() from ex6.s.
#include <stdio.h>

long max3(long a, long b, long c);

int main(void) {
    printf("max3(1, 9, 4) = %ld\n", max3(1, 9, 4));
    printf("max3(-5, -2, -9) = %ld\n", max3(-5, -2, -9));
    printf("max3(7, 7, 7) = %ld\n", max3(7, 7, 7));
    return 0;
}
