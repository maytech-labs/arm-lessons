// divide.s - unsigned division and the remainder (macOS).
//
// C:      unsigned long a = 100, b = 7;
//         unsigned long q = a / b;     // 14
//         unsigned long r = a % b;     // 2
//         return q * 10 + r;           // 142
// Build:  make
// Run:    ./divide; echo $?
// Expect: exit status 142

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #100                // a = 100
    mov x2, #7                  // b = 7
    udiv x3, x1, x2             // q = a / b = 14 (rounds toward zero)
    msub x4, x3, x2, x1         // r = a - q * b = 100 - 98 = 2
    mov x5, #10                 // x5 = 10
    madd x0, x3, x5, x4         // x0 = r + q * 10 = 142
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(142)
