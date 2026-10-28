// fp_add.s - add two doubles and print them with printf (lesson 23)
//
// Build: make fp_add
// Run:   ./fp_add
// Expected output:
//   1.500000 + 2.250000 = 3.750000

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!   // save frame pointer and return address
    mov x29, sp

    fmov d0, #1.5               // double a = 1.5;
    fmov d1, #2.25              // double b = 2.25;
    fadd d2, d0, d1             // double c = a + b;

    adrp x0, fmt                // printf(fmt, a, b, c):
    add x0, x0, :lo12:fmt       //   format in x0, the doubles in d0, d1, d2
    bl printf

    mov w0, #0                  // return 0;
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
fmt:
    .asciz "%f + %f = %f\n"
