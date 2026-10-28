// point.s - a struct is a block of memory with named offsets (macOS).
//
// C:      struct point { long x, y; };
//         struct point p = {3, 4};
//         struct point *q = &p;
//         q->x += 10;                                  // 13
//         long d2 = q->x * q->x + q->y * q->y;         // 185
//
// Build:  make
// Run:    ./point
// Expected output:
//   p = (13, 4), x*x + y*y = 185

    .global _main

    .equ POINT_X, 0             // offsetof(struct point, x)
    .equ POINT_Y, 8             // offsetof(struct point, y)
    .equ POINT_SIZE, 16         // sizeof(struct point)

    .data
    .p2align 3                  // a struct is aligned like its most aligned member
p:  .quad 3                     // p.x
    .quad 4                     // p.y

    .section __TEXT,__const
fmt:    .asciz "p = (%ld, %ld), x*x + y*y = %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, p@PAGE
    add x9, x9, p@PAGEOFF       // q = &p
    ldr x10, [x9, #POINT_X]     // q->x
    add x10, x10, #10
    str x10, [x9, #POINT_X]     // q->x += 10

    ldp x1, x2, [x9]            // x and y are neighbours: one ldp loads both
    mul x3, x1, x1
    madd x3, x2, x2, x3         // x*x + y*y
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
