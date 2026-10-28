// ex5_main.c - driver for ex5.s.
#include <stdio.h>

struct minmax { long min, max; };
struct minmax find_minmax(const long *a, long n);

int main(void) {
    long a[] = {3, 42, -7, 0, 15};
    struct minmax m = find_minmax(a, 5);
    printf("min %ld, max %ld\n", m.min, m.max);
    return 0;
}
