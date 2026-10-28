// signed_div.s - sdiv vs udiv on a negative number (macOS).
//
// C:      long a = -7, b = 2;
//         long q = a / b;              // -3 (C truncates toward zero)
//         long r = a % b;              // -1 (same sign as a)
//         return q;
// Build:  make
// Run:    ./signed_div; echo $?
// Expect: exit status 253 (-3 as a byte). In lldb: x4 = -1, x5 is huge.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #-7                 // a = -7 (0xfffffffffffffff9)
    mov x2, #2                  // b = 2
    sdiv x3, x1, x2             // q = -7 / 2 = -3 (signed division)
    msub x4, x3, x2, x1         // r = a - q * b = -7 - (-6) = -1
    udiv x5, x1, x2             // the same bits divided as UNSIGNED: 0x7ffffffffffffffc
    mov x0, x3                  // x0 = q = -3
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(-3): the shell sees 253
