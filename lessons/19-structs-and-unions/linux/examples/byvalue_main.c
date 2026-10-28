// byvalue_main.c - calls the struct functions written in byvalue.s.
#include <stdio.h>

struct pair { long a, b; };
struct triple { long a, b, c; };

struct pair swap_pair(struct pair p);
long sum_triple(struct triple t);
struct triple make_triple(long a, long b, long c);

int main(void) {
    struct pair p = swap_pair((struct pair){1, 2});
    printf("swap_pair({1, 2}) = {%ld, %ld}\n", p.a, p.b);
    printf("sum_triple({10, 20, 30}) = %ld\n", sum_triple((struct triple){10, 20, 30}));
    struct triple t = make_triple(7, 8, 9);
    printf("make_triple(7, 8, 9) = {%ld, %ld, %ld}\n", t.a, t.b, t.c);
    return 0;
}
