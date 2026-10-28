// ex6.s - Exercise 19.6: 24-byte structs by value, in and out (with ex6_main.c) (macOS).
//
//   struct vec3 { long x, y, z; };
//   struct vec3 vec3_add(struct vec3 a, struct vec3 b);
//
// Larger than 16 bytes, so: the caller copies a and b and passes pointers to
// the copies in x0 and x1, and passes the address for the result in x8.
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   (1, 2, 3) + (10, 20, 30) = (11, 22, 33)

    .global _vec3_add
    .text
    .p2align 2

_vec3_add:
    ldp x9, x10, [x0]           // a.x, a.y
    ldp x11, x12, [x1]          // b.x, b.y
    add x9, x9, x11
    add x10, x10, x12
    stp x9, x10, [x8]           // result->x, result->y
    ldr x9, [x0, #16]           // a.z
    ldr x11, [x1, #16]          // b.z
    add x9, x9, x11
    str x9, [x8, #16]           // result->z
    ret
