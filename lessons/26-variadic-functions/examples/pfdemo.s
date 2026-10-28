// pfdemo.s - calling our own variadic myprintf (myprintf.s) from assembly.
// Calling it is no different from calling printf.
//
// The C version:
//     myprintf("%s is %d years old (0x%x), grade %c\n", "Ada", 36, 36, 'A');
//     myprintf("%d %d %d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6, 7, 8, 9);
//
// Build and run:
//     make pfdemo          (links pfdemo.s with myprintf.s)
//     ./pfdemo
// Expected output:
//     Ada is 36 years old (0x24), grade A
//     1 2 3 4 5 6 7 8 9

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, fmt1
    add     x0, x0, :lo12:fmt1
    adrp    x1, name
    add     x1, x1, :lo12:name      // %s
    mov     w2, #36                 // %d
    mov     w3, #36                 // %x
    mov     w4, #'A'                // %c
    bl      myprintf

    // Nine variadic ints: 1-7 in x1-x7, 8 and 9 on the stack.
    sub     sp, sp, #16
    mov     x9, #8
    mov     x10, #9
    stp     x9, x10, [sp]           // [sp] = 8, [sp, #8] = 9
    adrp    x0, fmt2
    add     x0, x0, :lo12:fmt2
    mov     w1, #1
    mov     w2, #2
    mov     w3, #3
    mov     w4, #4
    mov     w5, #5
    mov     w6, #6
    mov     w7, #7
    bl      myprintf
    add     sp, sp, #16

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
fmt1:
    .asciz  "%s is %d years old (0x%x), grade %c\n"
fmt2:
    .asciz  "%d %d %d %d %d %d %d %d %d\n"
name:
    .asciz  "Ada"
