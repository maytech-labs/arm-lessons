// ex6_main.c - driver for ex6.s.
#include <stdio.h>

struct vec3 { long x, y, z; };
struct vec3 vec3_add(struct vec3 a, struct vec3 b);

int main(void) {
    struct vec3 a = {1, 2, 3}, b = {10, 20, 30};
    struct vec3 c = vec3_add(a, b);
    printf("(%ld, %ld, %ld) + (%ld, %ld, %ld) = (%ld, %ld, %ld)\n",
           a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z);
    return 0;
}
