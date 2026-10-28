// vector.s - a growable array (vector) of longs, grown with realloc (lesson 21, macOS)
//
// Build: make vector
// Run:   ./vector
// Expected output:
//   push 1: len=1 cap=4
//   push 4: len=2 cap=4
//   push 9: len=3 cap=4
//   push 16: len=4 cap=4
//   push 25: len=5 cap=8
//   push 36: len=6 cap=8
//   push 49: len=7 cap=8
//   push 64: len=8 cap=8
//   push 81: len=9 cap=16
//   push 100: len=10 cap=16
//   contents: 1 4 9 16 25 36 49 64 81 100

// struct Vec { long *data; long len; long cap; };
    .equ VEC_DATA, 0
    .equ VEC_LEN,  8
    .equ VEC_CAP,  16
    .equ VEC_SIZE, 24
    .equ VEC_FIRST_CAP, 4

    .section __TEXT,__cstring
fmt_push:
    .asciz "push %ld: len=%ld cap=%ld\n"
fmt_contents:
    .asciz "contents:"
fmt_elem:
    .asciz " %ld"

    .text
    .p2align 2

// void vec_init(struct Vec *v): an empty vector owns no memory yet
vec_init:
    str  xzr, [x0, #VEC_DATA]
    str  xzr, [x0, #VEC_LEN]
    str  xzr, [x0, #VEC_CAP]
    ret

// int vec_push(struct Vec *v, long x): returns 0, or -1 if out of memory
vec_push:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = v, x20 = x
    str x21, [sp, #32]              // x21 = newcap (must survive the realloc call)
    mov x19, x0
    mov x20, x1

    ldr  x2, [x19, #VEC_LEN]
    ldr  x3, [x19, #VEC_CAP]
    cmp  x2, x3
    b.ne vec_push_store             // room left: no need to grow

    // newcap = cap ? cap * 2 : VEC_FIRST_CAP
    lsl  x21, x3, #1
    mov  x4, #VEC_FIRST_CAP
    cmp  x21, #0
    csel x21, x4, x21, eq

    // p = realloc(v->data, newcap * sizeof(long));   realloc(NULL, n) acts like malloc(n)
    ldr  x0, [x19, #VEC_DATA]
    lsl  x1, x21, #3
    bl   _realloc
    cbz  x0, vec_push_fail          // old data is untouched and still owned by v
    str  x0, [x19, #VEC_DATA]       // v->data = p;
    str  x21, [x19, #VEC_CAP]       // v->cap = newcap;

vec_push_store:
    // v->data[v->len++] = x;
    ldr  x0, [x19, #VEC_DATA]
    ldr  x2, [x19, #VEC_LEN]
    str  x20, [x0, x2, lsl #3]
    add  x2, x2, #1
    str  x2, [x19, #VEC_LEN]
    mov  w0, #0
vec_push_done:
    ldr  x21, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #48
    ret
vec_push_fail:
    mov  w0, #-1
    b    vec_push_done

// long vec_get(struct Vec *v, long i)   (no bounds check, like C)
vec_get:
    ldr  x2, [x0, #VEC_DATA]
    ldr  x0, [x2, x1, lsl #3]
    ret

// void vec_free(struct Vec *v): give the memory back, leave v empty
vec_free:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr  x0, [x19, #VEC_DATA]
    bl   _free                      // free(NULL) is allowed and does nothing
    mov  x0, x19
    bl   vec_init
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    // frame: x29/x30 at [sp], x19/x20 at [sp, #16], struct Vec v at [sp, #32] (24 bytes)
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = i, x20 = i * i

    add  x0, sp, #32                // vec_init(&v);
    bl   vec_init

    // for (i = 1; i <= 10; i++) { vec_push(&v, i*i); printf(...); }
    mov  x19, #1
main_push_loop:
    cmp  x19, #10
    b.gt main_push_done
    mul  x20, x19, x19
    add  x0, sp, #32
    mov  x1, x20
    bl   vec_push
    cbnz w0, main_fail
    adrp x0, fmt_push@PAGE
    add  x0, x0, fmt_push@PAGEOFF
    mov  x1, x20
    ldr  x2, [sp, #32 + VEC_LEN]    // v.len   (read BEFORE sp moves)
    ldr  x3, [sp, #32 + VEC_CAP]    // v.cap
    sub  sp, sp, #32                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    str  x3, [sp, #16]
    bl   _printf
    add  sp, sp, #32
    add  x19, x19, #1
    b    main_push_loop
main_push_done:

    adrp x0, fmt_contents@PAGE      // printf("contents:");
    add  x0, x0, fmt_contents@PAGEOFF
    bl   _printf
    mov  x19, #0
main_print_loop:
    ldr  x2, [sp, #32 + VEC_LEN]
    cmp  x19, x2
    b.ge main_print_done
    add  x0, sp, #32                // printf(" %ld", vec_get(&v, i));
    mov  x1, x19
    bl   vec_get
    mov  x1, x0
    adrp x0, fmt_elem@PAGE
    add  x0, x0, fmt_elem@PAGEOFF
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16
    add  x19, x19, #1
    b    main_print_loop
main_print_done:
    mov  w0, #10                    // putchar('\n');
    bl   _putchar

    add  x0, sp, #32                // vec_free(&v);
    bl   vec_free
    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #64
    ret
main_fail:
    add  x0, sp, #32
    bl   vec_free
    mov  w0, #1
    b    main_done
