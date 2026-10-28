// pfdemo.s - calling our own variadic myprintf (myprintf.s) from assembly
// on macOS. Exactly like calling printf: every variadic argument on the stack.
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
    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    sub     sp, sp, #32                 // four slots
    adrp    x9, name@PAGE
    add     x9, x9, name@PAGEOFF
    mov     x10, #36
    stp     x9, x10, [sp]               // %s, %d
    mov     x9, #36
    mov     x10, #'A'
    stp     x9, x10, [sp, #16]          // %x, %c
    adrp    x0, fmt1@PAGE
    add     x0, x0, fmt1@PAGEOFF
    bl      _myprintf
    add     sp, sp, #32

    sub     sp, sp, #80                 // nine slots, rounded up to 80 bytes
    mov     x9, #1
    mov     x10, #2
    stp     x9, x10, [sp]
    mov     x9, #3
    mov     x10, #4
    stp     x9, x10, [sp, #16]
    mov     x9, #5
    mov     x10, #6
    stp     x9, x10, [sp, #32]
    mov     x9, #7
    mov     x10, #8
    stp     x9, x10, [sp, #48]
    mov     x9, #9
    str     x9, [sp, #64]
    adrp    x0, fmt2@PAGE
    add     x0, x0, fmt2@PAGEOFF
    bl      _myprintf
    add     sp, sp, #80

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
fmt1:
    .asciz  "%s is %d years old (0x%x), grade %c\n"
fmt2:
    .asciz  "%d %d %d %d %d %d %d %d %d\n"
name:
    .asciz  "Ada"
