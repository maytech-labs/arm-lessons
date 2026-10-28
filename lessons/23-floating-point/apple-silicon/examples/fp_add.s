// fp_add.s - add two doubles and print them with printf (lesson 23, macOS)
//
// Build: make fp_add
// Run:   ./fp_add
// Expected output:
//   1.500000 + 2.250000 = 3.750000

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!   // save frame pointer and return address
    mov x29, sp
    sub sp, sp, #32             // room for 3 variadic doubles (24 bytes, rounded to 32)

    fmov d0, #1.5               // double a = 1.5;
    fmov d1, #2.25              // double b = 2.25;
    fadd d2, d0, d1             // double c = a + b;

    str d0, [sp]                // variadic arguments go on the stack,
    str d1, [sp, #8]            //   8 bytes each, in order: a, b, c
    str d2, [sp, #16]
    adrp x0, fmt@PAGE           // the format string is a normal argument: x0
    add x0, x0, fmt@PAGEOFF
    bl _printf

    mov w0, #0                  // return 0;
    add sp, sp, #32
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
fmt:
    .asciz "%f + %f = %f\n"
