// ex4.s - Exercise 27.4: digit_sum, translated with the recipe.
//
//     int digit_sum(unsigned n) {
//         int s = 0;
//         while (n != 0) {
//             s += n % 10;
//             n /= 10;
//         }
//         return s;
//     }
//
// main prints digit_sum for four test values.
// Build: make
// Run:   ./ex4
// Expected output:
//     digit_sum(0) = 0
//     digit_sum(7) = 7
//     digit_sum(12345) = 15
//     digit_sum(4294967295) = 57

    .section .rodata
fmt:
    .asciz "digit_sum(%u) = %d\n"
    .p2align 2
tests:
    .word 0, 7, 12345, 4294967295
    .equ NTESTS, 4

    .text

// int digit_sum(unsigned n)
// Recipe: n in w0, result in w0. Variables n, s. No calls: a leaf, so
// scratch registers only and no frame.  w0 = n, w1 = s, w2 = 10,
// w3 = n / 10, w4 = n % 10.
    .global digit_sum
    .type digit_sum, %function
digit_sum:
    mov w1, #0                  // s = 0
    mov w2, #10
    cbz w0, 2f                  // guard: while (n != 0) may run zero times
1:
    udiv w3, w0, w2             // q = n / 10
    msub w4, w3, w2, w0         // r = n - q * 10
    add w1, w1, w4              // s += n % 10
    mov w0, w3                  // n /= 10
    cbnz w0, 1b                 // bottom-tested loop
2:
    mov w0, w1                  // return s
    ret
    .size digit_sum, .-digit_sum

// int main(void)
// Variables: p (pointer into tests), i (count), v (current value).
// All are used after printf, so: x19 = p, w20 = i, w21 = v.
// Frame: x29, x30, x19, x20, x21 = 40 bytes, rounded up to 48.
    .global main
    .type main, %function
main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]

    adrp x19, tests             // p = tests
    add x19, x19, :lo12:tests
    mov w20, #0                 // i = 0
1:
    ldr w21, [x19, w20, uxtw #2] // v = tests[i]
    mov w0, w21
    bl digit_sum
    mov w2, w0                  // printf(fmt, v, digit_sum(v))
    mov w1, w21
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    add w20, w20, #1
    cmp w20, #NTESTS
    b.lo 1b

    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
    .size main, .-main
