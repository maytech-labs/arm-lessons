// ex7.s - Exercise 16.7: long sum_array(const long *a, long n), called from C (macOS).
//
// Build: make ex7        (clang -g -arch arm64 -o ex7 ex7_main.c ex7.s)
// Run:   ./ex7
// Expected output:
//     sum = 31
//     empty sum = 0

    .text
    .global _sum_array
    .p2align 2
_sum_array:
    mov     x9, #0                  // total
    mov     x10, #0                 // i
sum_loop:
    cmp     x10, x1                 // while (i < n)
    b.ge    sum_done
    ldr     x11, [x0, x10, lsl #3]  // a[i]
    add     x9, x9, x11
    add     x10, x10, #1
    b       sum_loop
sum_done:
    mov     x0, x9
    ret
