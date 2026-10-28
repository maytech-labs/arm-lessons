// vtable.s - structs that carry a pointer to a table of functions (lesson 24, macOS)
//
// Build: make vtable
// Run:   ./vtable
// Expected output:
//   rectangle 6x4: area 24
//   triangle 6x4: area 12
//   square 5x5: area 25
//
// The C version:
//   struct shape;
//   struct shape_ops {                          // offset
//       long (*area)(const struct shape *);     //  0
//       const char *name;                       //  8
//   };
//   struct shape {
//       const struct shape_ops *ops;            //  0
//       long w;                                 //  8
//       long h;                                 // 16
//   };                                          // size 24
//
//   long rect_area(const struct shape *s)   { return s->w * s->h; }
//   long tri_area(const struct shape *s)    { return s->w * s->h / 2; }
//   long square_area(const struct shape *s) { return s->w * s->w; }
//
//   struct shape_ops rect_ops   = {rect_area,   "rectangle"};
//   struct shape_ops tri_ops    = {tri_area,    "triangle"};
//   struct shape_ops square_ops = {square_area, "square"};
//
//   struct shape shapes[3] = {
//       {&rect_ops, 6, 4}, {&tri_ops, 6, 4}, {&square_ops, 5, 5},
//   };
//   int main(void) {
//       for (long i = 0; i < 3; i++) {
//           struct shape *s = &shapes[i];
//           long a = s->ops->area(s);           // which area? the shape decides
//           printf("%s %ldx%ld: area %ld\n", s->ops->name, s->w, s->h, a);
//       }
//       return 0;
//   }

    .equ OPS_AREA,   0
    .equ OPS_NAME,   8
    .equ SHAPE_OPS,  0
    .equ SHAPE_W,    8
    .equ SHAPE_H,    16
    .equ SHAPE_SIZE, 24
    .equ NSHAPES,    3

    .text
    .global _main
    .p2align 2

// long rect_area(const struct shape *s)
rect_area:
    ldr x1, [x0, #SHAPE_W]
    ldr x2, [x0, #SHAPE_H]
    mul x0, x1, x2
    ret

// long tri_area(const struct shape *s)
tri_area:
    ldr x1, [x0, #SHAPE_W]
    ldr x2, [x0, #SHAPE_H]
    mul x0, x1, x2
    mov x3, #2
    sdiv x0, x0, x3
    ret

// long square_area(const struct shape *s)
square_area:
    ldr x1, [x0, #SHAPE_W]
    mul x0, x1, x1
    ret

_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    sub sp, sp, #32                 // room for printf's four variadic arguments
    adrp x19, shapes@PAGE           // x19 = s = &shapes[0]
    add  x19, x19, shapes@PAGEOFF
    mov  x20, #0                    // i
main_loop:
    cmp  x20, #NSHAPES
    b.ge main_done
    ldr  x21, [x19, #SHAPE_OPS]     // x21 = s->ops
    ldr  x9,  [x21, #OPS_AREA]      // x9  = s->ops->area
    mov  x0, x19                    // the shape passes itself as the argument
    blr  x9                         // a = s->ops->area(s)
    str  x0, [sp, #24]              // printf(fmt, name, w, h, a): a in the 4th slot
    ldr  x9, [x21, #OPS_NAME]
    ldr  x10, [x19, #SHAPE_W]
    ldr  x11, [x19, #SHAPE_H]
    stp  x9, x10, [sp]              // name, w
    str  x11, [sp, #16]             // h
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    bl   _printf
    add  x19, x19, #SHAPE_SIZE      // s++
    add  x20, x20, #1
    b    main_loop
main_done:
    add sp, sp, #32
    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .data                           // holds absolute addresses: must be writable
    .p2align 3
rect_ops:   .quad rect_area,   name_rect
tri_ops:    .quad tri_area,    name_tri
square_ops: .quad square_area, name_square
shapes:
    .quad rect_ops,   6, 4
    .quad tri_ops,    6, 4
    .quad square_ops, 5, 5

    .section __TEXT,__cstring
name_rect:   .asciz "rectangle"
name_tri:    .asciz "triangle"
name_square: .asciz "square"
fmt:         .asciz "%s %ldx%ld: area %ld\n"
