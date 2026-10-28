// ex5.s - Exercise 18.5: 25! as a 128-bit number (it needs 84 bits) (macOS).
//
// A 128-bit value (hi:lo) times a 64-bit n:
//     lo' = low64(lo * n)
//     hi' = hi * n + high64(lo * n)
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   25! = 0x00000000000cd4a0619fb0907bc00000

    .global _main

    .section __TEXT,__const
fmt:    .asciz "25! = 0x%016lx%016lx\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x9, #1                  // lo
    mov x10, #0                 // hi
    mov x11, #2                 // n
loop:
    umulh x12, x9, x11          // carry into the high half
    mul x9, x9, x11             // lo' = low 64 bits of lo * n
    madd x10, x10, x11, x12     // hi' = hi * n + carry
    add x11, x11, #1
    cmp x11, #25
    b.ls loop

    mov x1, x10
    mov x2, x9
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
