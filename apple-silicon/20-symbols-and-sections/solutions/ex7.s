// ex7.s - Exercise 20.7: a table of string pointers (macOS).
//
// C:      static const char *const months[] = {"Jan", "Feb", ..., "Dec"};
//         for each of 1, 6, 12: printf("%ld is %s\n", m, months[m - 1]);
//
// The strings are constants (.rodata). The table holds their addresses, which
// the loader may have to fix up, so it goes in writable .data.
//
// Build:  make
// Run:    ./ex7
// Expected output:
//   1 is Jan
//   6 is Jun
//   12 is Dec

    .global _main

    .section __TEXT,__const
m1:  .asciz "Jan"
m2:  .asciz "Feb"
m3:  .asciz "Mar"
m4:  .asciz "Apr"
m5:  .asciz "May"
m6:  .asciz "Jun"
m7:  .asciz "Jul"
m8:  .asciz "Aug"
m9:  .asciz "Sep"
m10: .asciz "Oct"
m11: .asciz "Nov"
m12: .asciz "Dec"
fmt: .asciz "%ld is %s\n"

    .data
    .p2align 3
months:
    .quad m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x0, #1
    bl show
    mov x0, #6
    bl show
    mov x0, #12
    bl show
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// void show(long m)
show:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x1, x0
    adrp x9, months@PAGE
    add x9, x9, months@PAGEOFF
    sub x10, x0, #1
    ldr x2, [x9, x10, lsl #3]   // months[m - 1]: a pointer
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
