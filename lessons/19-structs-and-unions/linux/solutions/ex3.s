// ex3.s - Exercise 19.3: an array of rectangles; total area and the widest one.
//
// C:      struct rect { long x, y, w, h; };              // 32 bytes
//         struct rect r[3] = {{0,0,4,5}, {2,3,10,1}, {1,1,3,3}};
//         total = sum of w*h;  widest = index with the largest w
//
// Build:  make
// Run:    ./ex3
// Expected output:
//   total area 39, widest is rect 1 at (2, 3)

    .global main

    .equ RECT_X, 0
    .equ RECT_Y, 8
    .equ RECT_W, 16
    .equ RECT_H, 24
    .equ RECT_SIZE, 32

    .data
    .p2align 3
rects:
    .quad 0, 0, 4, 5
    .quad 2, 3, 10, 1
    .quad 1, 1, 3, 3
    .equ COUNT, (. - rects) / RECT_SIZE

    .section .rodata
fmt:    .asciz "total area %ld, widest is rect %ld at (%ld, %ld)\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, rects
    add x9, x9, :lo12:rects     // p = &rects[0]
    mov x10, #COUNT             // count left
    mov x1, #0                  // total
    mov x11, #0                 // i
    mov x2, #0                  // widest index
    mov x12, #-1                // widest width so far
    mov x13, x9                 // pointer to the widest
loop:
    ldp x14, x15, [x9, #RECT_W] // w and h are neighbours
    madd x1, x14, x15, x1       // total += w * h
    cmp x14, x12
    csel x12, x14, x12, gt      // a wider one?
    csel x2, x11, x2, gt
    csel x13, x9, x13, gt
    add x9, x9, #RECT_SIZE      // p++ moves one whole struct
    add x11, x11, #1
    subs x10, x10, #1
    b.ne loop

    ldp x3, x4, [x13, #RECT_X]  // widest->x, widest->y
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
