// addresses.s - where static data, the stack, and the heap live (lesson 21, macOS)
//
// Build: make addresses
// Run:   ./addresses
// Expected output (the exact numbers change every run; the pattern does not):
//   static data: 0xaaaad5c20010
//   heap:        0xaaaaf9e8a2a0
//   stack:       0xffffd3b6f2d8
// The static and heap addresses are close together, low in memory.
// The stack address is far above them.

    .data
    .p2align 3
counter:
    .quad 7                     // a global: lives in static data

    .section __TEXT,__cstring
fmt_static:
    .asciz "static data: %p\n"
fmt_heap:
    .asciz "heap:        %p\n"
fmt_stack:
    .asciz "stack:       %p\n"

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!   // frame: x29, x30, x19, one local at [sp, #24]
    mov x29, sp
    str x19, [sp, #16]

    // printf("static data: %p\n", &counter);
    adrp x0, fmt_static@PAGE
    add  x0, x0, fmt_static@PAGEOFF
    adrp x1, counter@PAGE
    add  x1, x1, counter@PAGEOFF
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16

    // long *p = malloc(16);
    mov  x0, #16
    bl   _malloc
    cbz  x0, main_fail          // NULL means malloc failed
    mov  x19, x0                // keep p in a callee-saved register

    // printf("heap:        %p\n", p);
    adrp x0, fmt_heap@PAGE
    add  x0, x0, fmt_heap@PAGEOFF
    mov  x1, x19
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16

    // printf("stack:       %p\n", &local);   the local is at [sp, #24]
    adrp x0, fmt_stack@PAGE
    add  x0, x0, fmt_stack@PAGEOFF
    add  x1, sp, #24
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16

    // free(p);
    mov  x0, x19
    bl   _free

    mov  w0, #0
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
