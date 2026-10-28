// callvar.s - recap: calling a variadic function (printf) on Linux AArch64.
//
// The C version:
//     printf("%d + %d = %d, pi is about %.2f, name %s\n", 2, 3, 5, 3.14159, "Ada");
//     printf("%d %d %d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6, 7, 8, 9);
//
// On Linux a variadic argument goes exactly where a normal argument would:
// integers and pointers in x1-x7, doubles in d0-d7, and anything that does not
// fit in registers on the stack, 8 bytes per argument.
//
// Build and run:
//     make callvar
//     ./callvar
// Expected output:
//     2 + 3 = 5, pi is about 3.14, name Ada
//     1 2 3 4 5 6 7 8 9

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // First call: three ints, one double, one pointer.
    adrp    x0, fmt1
    add     x0, x0, :lo12:fmt1      // x0 = format (a named argument)
    mov     w1, #2                  // first variadic int  -> x1
    mov     w2, #3                  // second              -> x2
    mov     w3, #5                  // third               -> x3
    adrp    x9, pi
    ldr     d0, [x9, :lo12:pi]      // the double goes in d0, not in x4
    adrp    x4, name
    add     x4, x4, :lo12:name      // the pointer is the next integer slot: x4
    bl      printf

    // Second call: nine ints. x1-x7 take seven of them, 8 and 9 go on the stack.
    sub     sp, sp, #16             // two 8-byte slots, sp stays 16-byte aligned
    mov     w9, #8
    str     x9, [sp]                // 8th variadic argument at [sp]
    mov     w9, #9
    str     x9, [sp, #8]            // 9th at [sp, #8]
    adrp    x0, fmt2
    add     x0, x0, :lo12:fmt2
    mov     w1, #1
    mov     w2, #2
    mov     w3, #3
    mov     w4, #4
    mov     w5, #5
    mov     w6, #6
    mov     w7, #7
    bl      printf
    add     sp, sp, #16             // drop the argument area

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
fmt1:
    .asciz  "%d + %d = %d, pi is about %.2f, name %s\n"
fmt2:
    .asciz  "%d %d %d %d %d %d %d %d %d\n"
name:
    .asciz  "Ada"
    .p2align 3
pi:
    .double 3.14159
