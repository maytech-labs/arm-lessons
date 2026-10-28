// greet.s - an assembly function, called from C, that itself calls printf
// (macOS).
//
// C version of the function:
//     void greet(const char *name, int times) {
//         for (int i = 1; i <= times; i++)
//             printf("%d: Hello, %s!\n", i, name);
//     }
//
// Build: make greet       (clang -g -arch arm64 -o greet greet_main.c greet.s)
// Run:   ./greet
// Expected output:
//     1: Hello, world!
//     1: Hello, Ada!
//     2: Hello, Ada!

    .section __TEXT,__cstring
fmt:
    .asciz  "%d: Hello, %s!\n"

    .text
    .global _greet
    .p2align 2
_greet:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    sub     sp, sp, #16             // printf's 2 variadic slots, reused each call

    mov     x19, x0                 // x19 = name
    mov     w20, w1                 // w20 = times
    mov     w21, #1                 // w21 = i
greet_loop:
    cmp     w21, w20                // while (i <= times)
    b.gt    greet_done
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    str     x21, [sp]               // slot 0 = i (mov w21 zeroed the top half)
    str     x19, [sp, #8]           // slot 1 = name
    bl      _printf
    add     w21, w21, #1
    b       greet_loop
greet_done:
    add     sp, sp, #16
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
