// add128.s - 128-bit addition and subtraction with the carry flag (macOS).
//
// C:      unsigned __int128 a = ((unsigned __int128)1 << 64) - 1;   // 2^64 - 1
//         a = a + 1;                                               // 2^64
//         a = a - 2;                                               // 2^64 - 2
//
// Build:  make
// Run:    ./add128
// Expected output:
//   2^64 - 1 = 0x0000000000000000ffffffffffffffff
//   + 1      = 0x00000000000000010000000000000000
//   - 2      = 0x0000000000000000fffffffffffffffe

    .global _main

    .section __TEXT,__const
fmt1:   .asciz "2^64 - 1 = 0x%016lx%016lx\n"
fmt2:   .asciz "+ 1      = 0x%016lx%016lx\n"
fmt3:   .asciz "- 2      = 0x%016lx%016lx\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    mov x19, #-1                // low half
    mov x20, #0                 // high half
    mov x1, x20
    mov x2, x19
    adrp x0, fmt1@PAGE
    add x0, x0, fmt1@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    adds x19, x19, #1           // low + 1: wraps to 0 and sets C (carry out)
    adc x20, x20, xzr           // high + 0 + C
    mov x1, x20
    mov x2, x19
    adrp x0, fmt2@PAGE
    add x0, x0, fmt2@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    subs x19, x19, #2           // low - 2: borrows, so C is cleared
    sbc x20, x20, xzr           // high - 0 - (1 - C): takes the borrow
    mov x1, x20
    mov x2, x19
    adrp x0, fmt3@PAGE
    add x0, x0, fmt3@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
