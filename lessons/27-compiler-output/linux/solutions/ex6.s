// ex6.s - Exercise 27.6: count primes, with values kept in callee-saved
// registers across calls.
//
//     int is_prime(int k) {
//         if (k < 2) return 0;
//         for (int d = 2; d * d <= k; d++)
//             if (k % d == 0) return 0;
//         return 1;
//     }
//
//     int count_primes(int n) {          // primes p with 2 <= p < n
//         int count = 0;
//         for (int k = 2; k < n; k++)
//             count += is_prime(k);
//         return count;
//     }
//
// Build: make
// Run:   ./ex6
// Expected output:
//     primes below 10: 4
//     primes below 100: 25
//     primes below 1000: 168
//     primes below 10000: 1229

    .section .rodata
fmt:
    .asciz "primes below %d: %d\n"

    .text

// int is_prime(int k)
// Leaf: w0 = k, w1 = d, w2 = d * d, w3 = k / d, w4 = k % d.
    .global is_prime
    .type is_prime, %function
is_prime:
    cmp w0, #2
    b.lt 3f                     // k < 2: not prime
    mov w1, #2                  // d = 2
1:
    mul w2, w1, w1
    cmp w2, w0
    b.gt 2f                     // d * d > k: no divisor found
    sdiv w3, w0, w1
    msub w4, w3, w1, w0         // k % d
    cbz w4, 3f                  // divides: not prime
    add w1, w1, #1
    b 1b
2:
    mov w0, #1
    ret
3:
    mov w0, #0
    ret
    .size is_prime, .-is_prime

// int count_primes(int n)
// Variables n, count, k: all used after the call to is_prime.
//     w19 = n, w20 = k, w21 = count
// Frame: x29, x30 + 3 registers = 40, rounded up to 48.
//     [sp, #0] x29  [sp, #8] x30  [sp, #16] x19  [sp, #24] x20  [sp, #32] x21
    .global count_primes
    .type count_primes, %function
count_primes:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]

    mov w19, w0                 // n
    mov w21, #0                 // count = 0
    mov w20, #2                 // k = 2
    cmp w20, w19
    b.ge 2f                     // guard: k < n false at the start
1:
    mov w0, w20
    bl is_prime
    add w21, w21, w0            // count += is_prime(k)
    add w20, w20, #1            // k++
    cmp w20, w19
    b.lt 1b                     // bottom-tested
2:
    mov w0, w21

    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
    .size count_primes, .-count_primes

// int main(void): for (n = 10; n <= 10000; n *= 10) printf(...)
// w19 = n (used after calls). Frame: 16 + 8 -> 32.
    .global main
    .type main, %function
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov w19, #10
1:
    mov w0, w19
    bl count_primes
    mov w2, w0
    mov w1, w19
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    mov w9, #10
    mul w19, w19, w9            // n *= 10
    mov w9, #10000              // too big for cmp's 12-bit immediate
    cmp w19, w9
    b.le 1b

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
    .size main, .-main
