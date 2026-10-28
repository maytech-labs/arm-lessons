// ex6.s - a heap array of pointers to heap structs (lesson 21, macOS, exercise 21.6)
//
// Build: make ex6
// Run:   ./ex6
// Expected output:
//   rect 0: 2 x 3 = 6
//   rect 1: 4 x 5 = 20
//   rect 2: 10 x 10 = 100
//   total area 126

// struct Rect { long w; long h; };
    .equ RECT_W, 0
    .equ RECT_H, 8
    .equ RECT_SIZE, 16
    .equ PTR_SIZE, 8                // sizeof(struct Rect *)
    .equ COUNT, 3

    .section __TEXT,__const         // read-only data that is not strings
    .p2align 3
widths:
    .quad 2, 4, 10
heights:
    .quad 3, 5, 10

    .section __TEXT,__cstring
fmt_rect:
    .asciz "rect %ld: %ld x %ld = %ld\n"
fmt_total:
    .asciz "total area %ld\n"

    .text
    .p2align 2

// struct Rect *rect_new(long w, long h): caller owns the result
rect_new:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
    mov  x0, #RECT_SIZE
    bl   _malloc
    cbz  x0, rect_new_done
    str  x19, [x0, #RECT_W]
    str  x20, [x0, #RECT_H]
rect_new_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

// long rect_area(const struct Rect *r)
rect_area:
    ldr  x1, [x0, #RECT_W]
    ldr  x2, [x0, #RECT_H]
    mul  x0, x1, x2
    ret

// void free_rects(struct Rect **rs, long n): free every rect, then the array.
// Safe on a partly filled array as long as the unused slots are NULL.
free_rects:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
free_rects_loop:
    subs x20, x20, #1
    b.lt free_rects_done
    ldr  x0, [x19, x20, lsl #3]     // free(rs[i]);
    bl   _free
    b    free_rects_loop
free_rects_done:
    mov  x0, x19                    // free(rs);
    bl   _free
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = rs, x20 = i
    str x21, [sp, #32]              // x21 = total

    // struct Rect **rs = calloc(COUNT, sizeof(struct Rect *));   NULL-filled
    mov  x0, #COUNT
    mov  x1, #PTR_SIZE
    bl   _calloc
    cbz  x0, main_fail
    mov  x19, x0

    mov  x20, #0                    // for (i = 0; i < COUNT; i++) rs[i] = rect_new(w[i], h[i]);
main_make:
    cmp  x20, #COUNT
    b.ge main_make_done
    adrp x0, widths@PAGE
    add  x0, x0, widths@PAGEOFF
    ldr  x0, [x0, x20, lsl #3]
    adrp x1, heights@PAGE
    add  x1, x1, heights@PAGEOFF
    ldr  x1, [x1, x20, lsl #3]
    bl   rect_new
    cbz  x0, main_cleanup_fail
    str  x0, [x19, x20, lsl #3]
    add  x20, x20, #1
    b    main_make
main_make_done:

    mov  x21, #0
    mov  x20, #0
main_print:
    cmp  x20, #COUNT
    b.ge main_print_done
    ldr  x0, [x19, x20, lsl #3]
    bl   rect_area
    add  x21, x21, x0
    mov  x4, x0                     // printf("rect %ld: %ld x %ld = %ld\n", i, w, h, area);
    ldr  x5, [x19, x20, lsl #3]
    ldr  x2, [x5, #RECT_W]
    ldr  x3, [x5, #RECT_H]
    mov  x1, x20
    adrp x0, fmt_rect@PAGE
    add  x0, x0, fmt_rect@PAGEOFF
    sub  sp, sp, #32                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    str  x3, [sp, #16]
    str  x4, [sp, #24]
    bl   _printf
    add  sp, sp, #32
    add  x20, x20, #1
    b    main_print
main_print_done:
    adrp x0, fmt_total@PAGE
    add  x0, x0, fmt_total@PAGEOFF
    mov  x1, x21
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16

    mov  x0, x19
    mov  x1, #COUNT
    bl   free_rects
    mov  w0, #0
main_done:
    ldr  x21, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #48
    ret
main_cleanup_fail:
    mov  x0, x19                    // slots not filled yet are still NULL
    mov  x1, #COUNT
    bl   free_rects
main_fail:
    mov  w0, #1
    b    main_done
