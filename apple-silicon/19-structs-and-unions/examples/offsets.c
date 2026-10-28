// offsets.c - what the C compiler decides about struct layout.
// The assembly examples use .equ offsets; this program prints the real ones
// so you can check them.
//
// Build:  make
// Run:    ./offsets
// Expected output:
//   struct point: size 16, x at 0, y at 8
//   struct padded: size 12, c at 0, i at 4, d at 8
//   struct packed: size 8, i at 0, c at 4, d at 5
//   struct student: size 24, name at 0, age at 16, score at 20
#include <stdio.h>
#include <stddef.h>

struct point   { long x, y; };
struct padded  { char c; int i; char d; };
struct packed  { int i; char c; char d; };
struct student { char name[16]; int age; int score; };

int main(void) {
    printf("struct point: size %zu, x at %zu, y at %zu\n",
           sizeof(struct point), offsetof(struct point, x), offsetof(struct point, y));
    printf("struct padded: size %zu, c at %zu, i at %zu, d at %zu\n",
           sizeof(struct padded), offsetof(struct padded, c),
           offsetof(struct padded, i), offsetof(struct padded, d));
    printf("struct packed: size %zu, i at %zu, c at %zu, d at %zu\n",
           sizeof(struct packed), offsetof(struct packed, i),
           offsetof(struct packed, c), offsetof(struct packed, d));
    printf("struct student: size %zu, name at %zu, age at %zu, score at %zu\n",
           sizeof(struct student), offsetof(struct student, name),
           offsetof(struct student, age), offsetof(struct student, score));
    return 0;
}
