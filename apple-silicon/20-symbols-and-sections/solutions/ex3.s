// ex3.s - Exercise 20.3: two functions, each with its own static counter (macOS).
//
// C:      long next_id(void)    { static long n = 0;  return ++n; }
//         long next_even(void)  { static long n = 0;  return n += 2; }
//
// Build:  make
// Run:    ./ex3
// Expected output:
//   ids: 1 2 3, evens: 2 4 6

    .global _main

    .data
    .p2align 3
next_id_n:   .quad 0            // two different "n"s: two different symbols
next_even_n: .quad 0

    .section __TEXT,__const
fmt:    .asciz "ids: %ld %ld %ld, evens: %ld %ld %ld\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    bl next_id
    mov x19, x0
    bl next_id
    mov x20, x0
    bl next_id
    mov x21, x0
    bl next_even
    mov x22, x0
    bl next_even
    mov x23, x0
    bl next_even
    mov x6, x0
    mov x1, x19
    mov x2, x20
    mov x3, x21
    mov x4, x22
    mov x5, x23
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #48             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    str x4, [sp, #24]
    str x5, [sp, #32]
    str x6, [sp, #40]
    bl _printf
    add sp, sp, #48
    mov w0, #0
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

next_id:
    adrp x9, next_id_n@PAGE
    add x9, x9, next_id_n@PAGEOFF
    ldr x0, [x9]
    add x0, x0, #1              // ++n
    str x0, [x9]
    ret

next_even:
    adrp x9, next_even_n@PAGE
    add x9, x9, next_even_n@PAGEOFF
    ldr x0, [x9]
    add x0, x0, #2              // n += 2
    str x0, [x9]
    ret
