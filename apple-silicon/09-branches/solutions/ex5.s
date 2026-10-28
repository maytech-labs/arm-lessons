// ex5.s - Exercise 09.5: is a year a leap year? (macOS)
//
// C:      long y = 2024, leap = 0;
//         if ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)
//             leap = 1;
//         return leap;
// Build:  make
// Run:    ./ex5; echo $?
// Expect: exit status 1. With y = 1900: 0. With y = 2000: 1. With y = 2023: 0.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #2024               // y = 2024
    mov x0, #0                  // leap = 0

    // left side of ||:  (y % 4 == 0 && y % 100 != 0)
    mov x2, #4                  // divisor 4
    udiv x3, x1, x2             // y / 4
    msub x3, x3, x2, x1         // x3 = y % 4
    cbnz x3, try_400            // y % 4 != 0: the && is false, try the right side
    mov x2, #100                // divisor 100
    udiv x3, x1, x2             // y / 100
    msub x3, x3, x2, x1         // x3 = y % 100
    cbnz x3, is_leap            // y % 100 != 0: the && is true, so the || is true

try_400:
    // right side of ||:  y % 400 == 0
    mov x2, #400                // divisor 400
    udiv x3, x1, x2             // y / 400
    msub x3, x3, x2, x1         // x3 = y % 400
    cbnz x3, done               // y % 400 != 0: everything false, leap stays 0

is_leap:
    mov x0, #1                  // leap = 1
done:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(leap)
