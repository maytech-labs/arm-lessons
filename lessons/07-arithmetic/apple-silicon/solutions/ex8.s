// ex8.s - Exercise 07.8: the sum of the decimal digits of 2024, no loops (macOS).
//
// C:      long n = 2024;
//         long d0 = n % 10;  n = n / 10;   // 4
//         long d1 = n % 10;  n = n / 10;   // 2
//         long d2 = n % 10;  n = n / 10;   // 0
//         long d3 = n;                     // 2
//         return d0 + d1 + d2 + d3;        // 8
// Build:  make
// Run:    ./ex8; echo $?
// Expect: exit status 8

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #2024               // n = 2024
    mov x2, #10                 // the divisor, 10
    mov x0, #0                  // sum = 0

    udiv x3, x1, x2             // q = 202
    msub x4, x3, x2, x1         // digit = 2024 - 2020 = 4
    add x0, x0, x4              // sum = 4
    mov x1, x3                  // n = 202

    udiv x3, x1, x2             // q = 20
    msub x4, x3, x2, x1         // digit = 2
    add x0, x0, x4              // sum = 6
    mov x1, x3                  // n = 20

    udiv x3, x1, x2             // q = 2
    msub x4, x3, x2, x1         // digit = 0
    add x0, x0, x4              // sum = 6
    mov x1, x3                  // n = 2

    add x0, x0, x1              // the last digit is n itself: sum = 8
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(8)
