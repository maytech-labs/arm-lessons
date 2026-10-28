// ex4.s - Exercise 18.4: saturating 32-bit signed addition (macOS).
//
// C:      int sat_add(int a, int b) {
//             int r;
//             if (__builtin_add_overflow(a, b, &r)) return a < 0 ? INT_MIN : INT_MAX;
//             return r;
//         }
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   2147483647 -2147483648 30 -2147483648

    .global _main

    .section __TEXT,__const
fmt:    .asciz "%d %d %d %d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov w0, #0x7fffffff         // INT_MAX + 1
    mov w1, #1
    bl sat_add
    mov w19, w0
    mov w0, #0x80000000         // INT_MIN + (-1)
    mov w1, #-1
    bl sat_add
    mov w20, w0
    mov w0, #10                 // an ordinary sum
    mov w1, #20
    bl sat_add
    mov w21, w0
    mov w0, #0x80000000         // INT_MIN + INT_MIN
    mov w1, #0x80000000
    bl sat_add
    mov w22, w0

    mov w1, w19
    mov w2, w20
    mov w3, w21
    mov w4, w22
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    str x4, [sp, #24]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// int sat_add(int a, int b): leaf, branchless
sat_add:
    mov w9, #0x7fffffff         // INT_MAX
    mov w10, #0x80000000        // INT_MIN
    cmp w0, #0
    csel w9, w10, w9, lt        // the limit to use if it overflows: by a's sign
    adds w0, w0, w1             // the sum, setting V on signed overflow
    csel w0, w9, w0, vs         // overflowed: the limit; otherwise the sum
    ret
