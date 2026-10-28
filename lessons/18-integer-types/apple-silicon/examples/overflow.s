// overflow.s - signed overflow: C calls it undefined; the CPU just wraps, (macOS)
// and sets V. Check it with adds and b.vs (or cset vs).
//
// C (gcc builtin):
//         int r;
//         int bad = __builtin_add_overflow(2147483647, 1, &r);   // 1, r wraps
//
// Build:  make
// Run:    ./overflow
// Expected output:
//   2147483647 + 1 = -2147483648, overflow = 1
//   2147483646 + 1 = 2147483647, overflow = 0

    .global _main

    .section __TEXT,__const
fmt:    .asciz "%d + 1 = %d, overflow = %d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov w19, #0x7fffffff        // INT_MAX
    mov w1, w19
    adds w2, w19, #1            // 32-bit add that sets the flags
    cset w3, vs                 // V: signed overflow happened
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    sub w19, w19, #1            // INT_MAX - 1
    mov w1, w19
    adds w2, w19, #1
    cset w3, vs
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
