// printnum.s - print the number in x19 in decimal.
//
// Build:  make
// Run:    ./printnum
// Expect: 1234567
//
// C equivalent:
//     char buf[32];
//     unsigned long n = 1234567;
//     char *p = buf + 32;               // start at the end
//     *--p = '\n';
//     do {
//         *--p = '0' + n % 10;          // last digit first
//         n = n / 10;
//     } while (n != 0);
//     write(1, p, (buf + 32) - p);

    .global _main

    .bss
numbuf:
    .space 32                   // a 64-bit number has at most 20 digits

    .text
    .p2align 2

_main:
    movz x19, #0x12, lsl #16    // x19 = 0x12d687 = 1234567
    movk x19, #0xd687

    // ---- print x19 in decimal, followed by a newline ----
    adrp x1, numbuf@PAGE
    add x1, x1, numbuf@PAGEOFF
    add x5, x1, #32             // x5 = end of buffer (one past the last byte)
    mov x1, x5                  // x1 = p, moves backwards
    mov w2, #10                 // '\n'
    strb w2, [x1, #-1]!         // *--p = '\n'
    mov x2, x19                 // x2 = n, the number being printed
    mov x3, #10                 // the divisor
digit:
    udiv x4, x2, x3             // x4 = n / 10
    msub x6, x4, x3, x2         // x6 = n - (n / 10) * 10 = n % 10
    add w6, w6, #'0'            // 0..9 -> '0'..'9'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x2, x4                  // n = n / 10
    cbnz x2, digit              // do ... while (n != 0)
    mov x0, #1                  // fd 1 = stdout
                                // x1 = p, the first digit
    sub x2, x5, x1              // length = end - p
    mov x16, #4                 // 4 = write
    svc #0x80
    // ---- end of print ----

    mov x0, #0
    mov x16, #1                 // 1 = exit
    svc #0x80
