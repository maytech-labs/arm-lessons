// ex5.s - vector with pop and sum (lesson 21, macOS, exercise 21.5)
//
// Build: make ex5
// Run:   ./ex5
// Expected output:
//   popped 20
//   popped 19
//   popped 18
//   popped 17
//   popped 16
//   len=15 cap=32 sum=120

// struct Vec { long *data; long len; long cap; };
    .equ VEC_DATA, 0
    .equ VEC_LEN,  8
    .equ VEC_CAP,  16
    .equ VEC_SIZE, 24
    .equ VEC_FIRST_CAP, 4

    .section __TEXT,__cstring
fmt_pop:
    .asciz "popped %ld\n"
fmt_end:
    .asciz "len=%ld cap=%ld sum=%ld\n"

    .text
    .p2align 2

vec_init:
    str  xzr, [x0, #VEC_DATA]
    str  xzr, [x0, #VEC_LEN]
    str  xzr, [x0, #VEC_CAP]
    ret

// int vec_push(struct Vec *v, long x): 0 on success, -1 if out of memory
vec_push:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, x0
    mov x20, x1
    ldr  x2, [x19, #VEC_LEN]
    ldr  x3, [x19, #VEC_CAP]
    cmp  x2, x3
    b.ne vec_push_store
    lsl  x21, x3, #1
    mov  x4, #VEC_FIRST_CAP
    cmp  x21, #0
    csel x21, x4, x21, eq
    ldr  x0, [x19, #VEC_DATA]
    lsl  x1, x21, #3
    bl   _realloc
    cbz  x0, vec_push_fail
    str  x0, [x19, #VEC_DATA]
    str  x21, [x19, #VEC_CAP]
vec_push_store:
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

// long vec_pop(struct Vec *v): remove and return the last element.
// The caller must make sure v->len > 0. The memory is kept for later pushes.
vec_pop:
    ldr  x1, [x0, #VEC_LEN]
    sub  x1, x1, #1                 // v->len--;
    str  x1, [x0, #VEC_LEN]
    ldr  x2, [x0, #VEC_DATA]
    ldr  x0, [x2, x1, lsl #3]       // return v->data[v->len];
    ret

// long vec_sum(const struct Vec *v)
vec_sum:
    ldr  x1, [x0, #VEC_DATA]
    ldr  x2, [x0, #VEC_LEN]
    mov  x0, #0                     // sum
    mov  x3, #0                     // i
vec_sum_loop:
    cmp  x3, x2
    b.ge vec_sum_done
    ldr  x4, [x1, x3, lsl #3]
    add  x0, x0, x4
    add  x3, x3, #1
    b    vec_sum_loop
vec_sum_done:
    ret

vec_free:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr  x0, [x19, #VEC_DATA]
    bl   _free
    mov  x0, x19
    bl   vec_init
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-64]!       // struct Vec v at [sp, #32]
    mov x29, sp
    str x19, [sp, #16]              // x19 = i

    add  x0, sp, #32
    bl   vec_init

    mov  x19, #1                    // for (i = 1; i <= 20; i++) vec_push(&v, i);
main_push:
    cmp  x19, #20
    b.gt main_push_done
    add  x0, sp, #32
    mov  x1, x19
    bl   vec_push
    cbnz w0, main_fail
    add  x19, x19, #1
    b    main_push
main_push_done:

    mov  x19, #0                    // for (i = 0; i < 5; i++) printf("popped %ld\n", vec_pop(&v));
main_pop:
    cmp  x19, #5
    b.ge main_pop_done
    add  x0, sp, #32
    bl   vec_pop
    mov  x1, x0
    adrp x0, fmt_pop@PAGE
    add  x0, x0, fmt_pop@PAGEOFF
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16
    add  x19, x19, #1
    b    main_pop
main_pop_done:

    add  x0, sp, #32
    bl   vec_sum
    mov  x3, x0
    adrp x0, fmt_end@PAGE
    add  x0, x0, fmt_end@PAGEOFF
    ldr  x1, [sp, #32 + VEC_LEN]
    ldr  x2, [sp, #32 + VEC_CAP]
    sub  sp, sp, #32                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    str  x3, [sp, #16]
    bl   _printf
    add  sp, sp, #32

    add  x0, sp, #32
    bl   vec_free
    mov  w0, #0
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #64
    ret
main_fail:
    add  x0, sp, #32
    bl   vec_free
    mov  w0, #1
    b    main_done
