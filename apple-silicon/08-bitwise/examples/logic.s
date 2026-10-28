// logic.s - and, orr, eor, bic, mvn on two small numbers (macOS).
//
// C:      unsigned long a = 0xc, b = 0xa;     // 0b1100 and 0b1010
//         unsigned long x = a & b;            // 0b1000 = 8
//         unsigned long y = a | b;            // 0b1110 = 14
//         unsigned long z = a ^ b;            // 0b0110 = 6
//         unsigned long c = a & ~b;           // 0b0100 = 4
//         unsigned long n = ~a;               // 0xfffffffffffffff3
//         return x + y + z;                   // 28
// Build:  make
// Run:    ./logic; echo $?
// Expect: exit status 28. Look at x4 and x5 in lldb.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #0xc                // a = 0b1100
    mov x2, #0xa                // b = 0b1010
    and x3, x1, x2              // x = a & b  = 0b1000 = 8
    orr x6, x1, x2              // y = a | b  = 0b1110 = 14
    eor x7, x1, x2              // z = a ^ b  = 0b0110 = 6
    bic x4, x1, x2              // c = a & ~b = 0b0100 = 4  ("bit clear")
    mvn x5, x1                  // n = ~a     = 0xfffffffffffffff3
    add x0, x3, x6              // x0 = 8 + 14 = 22
    add x0, x0, x7              // x0 = 22 + 6 = 28
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(28)
