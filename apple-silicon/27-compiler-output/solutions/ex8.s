// ex8.s - Exercise 27.8: count_primes in assembly, for ex8_main.c to time
// against the same C compiled with clang -O2 (macOS).
//
// This file has no _main; it is linked with ex8_main.c.
// Build: make
// Run:   ./ex8
// Expected output: both counts are 17984. Times vary, for example:
//     asm:     count = 17984   time = 0.057 s
//     C -O2:   count = 17984   time = 0.055 s

    .text

// int is_prime_asm(int k): leaf, as in ex6.s.
    .global _is_prime_asm
    .p2align 2
_is_prime_asm:
    cmp w0, #2
    b.lt 3f
    mov w1, #2
1:
    mul w2, w1, w1
    cmp w2, w0
    b.gt 2f
    sdiv w3, w0, w1
    msub w4, w3, w1, w0
    cbz w4, 3f
    add w1, w1, #1
    b 1b
2:
    mov w0, #1
    ret
3:
    mov w0, #0
    ret

// int count_primes_asm(int n): as in ex6.s.
// w19 = n, w20 = k, w21 = count. Frame 48.
    .global _count_primes_asm
    .p2align 2
_count_primes_asm:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov w19, w0
    mov w21, #0
    mov w20, #2
    cmp w20, w19
    b.ge 2f
1:
    mov w0, w20
    bl _is_prime_asm
    add w21, w21, w0
    add w20, w20, #1
    cmp w20, w19
    b.lt 1b
2:
    mov w0, w21
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
