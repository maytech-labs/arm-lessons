// ex3.s - my_strdup: copy a string into new heap memory (lesson 21, macOS, exercise 21.3)
//
// Build: make ex3
// Run:   ./ex3
// Expected output:
//   original: hello
//   copy:     Jello

    .section __TEXT,__cstring
hello:
    .asciz "hello"
fmt_orig:
    .asciz "original: %s\n"
fmt_copy:
    .asciz "copy:     %s\n"

    .text
    .p2align 2

// char *my_strdup(const char *s): returns a malloc'd copy, or NULL.
// The caller owns the result and must free it.
my_strdup:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = s, x20 = n
    mov x19, x0

    bl   _strlen                    // n = strlen(s) + 1;
    add  x20, x0, #1
    mov  x0, x20                    // copy = malloc(n);
    bl   _malloc
    cbz  x0, my_strdup_done         // return NULL

    mov  x1, x19                    // copy n bytes, including the '\0'
    mov  x2, #0
my_strdup_loop:
    cmp  x2, x20
    b.ge my_strdup_done             // x0 still holds copy
    ldrb w3, [x1, x2]
    strb w3, [x0, x2]
    add  x2, x2, #1
    b    my_strdup_loop
my_strdup_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]              // x19 = copy

    adrp x0, hello@PAGE             // copy = my_strdup("hello");
    add  x0, x0, hello@PAGEOFF
    bl   my_strdup
    cbz  x0, main_fail
    mov  x19, x0

    mov  w1, #'J'                   // copy[0] = 'J';   the original is read-only
    strb w1, [x19]

    adrp x0, fmt_orig@PAGE
    add  x0, x0, fmt_orig@PAGEOFF
    adrp x1, hello@PAGE
    add  x1, x1, hello@PAGEOFF
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16
    adrp x0, fmt_copy@PAGE
    add  x0, x0, fmt_copy@PAGEOFF
    mov  x1, x19
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16

    mov  x0, x19                    // free(copy);   we own it
    bl   _free
    mov  w0, #0
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
