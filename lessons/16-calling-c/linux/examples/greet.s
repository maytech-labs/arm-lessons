// greet.s - an assembly function, called from C, that itself calls printf.
//
// C version of the function:
//     void greet(const char *name, int times) {
//         for (int i = 1; i <= times; i++)
//             printf("%d: Hello, %s!\n", i, name);
//     }
//
// Build: make greet       (gcc -g -o greet greet_main.c greet.s)
// Run:   ./greet
// Expected output:
//     1: Hello, world!
//     1: Hello, Ada!
//     2: Hello, Ada!

    .section .rodata
fmt:
    .asciz  "%d: Hello, %s!\n"

    .text
    .global greet
    .p2align 2
greet:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // we use three callee-saved registers,
    str     x21, [sp, #32]          // so we must save and restore them

    mov     x19, x0                 // x19 = name
    mov     w20, w1                 // w20 = times
    mov     w21, #1                 // w21 = i
greet_loop:
    cmp     w21, w20                // while (i <= times)
    b.gt    greet_done
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    mov     w1, w21
    mov     x2, x19
    bl      printf
    add     w21, w21, #1
    b       greet_loop
greet_done:
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
