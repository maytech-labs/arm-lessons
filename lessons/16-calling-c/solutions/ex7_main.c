// ex7_main.c - Exercise 16.7: calls sum_array() from ex7.s.
#include <stdio.h>

long sum_array(const long *a, long n);

int main(void) {
    long digits[] = {3, 1, 4, 1, 5, 9, 2, 6};
    printf("sum = %ld\n", sum_array(digits, 8));
    printf("empty sum = %ld\n", sum_array(digits, 0));
    return 0;
}
