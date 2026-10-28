// ex9.s - print a signed number.
//
// Build:  make
// Run:    ./ex9
// Expect: -12345
//
// C equivalent:
//     long v = -12345;
//     unsigned long n = v < 0 ? -v : v;
//     ... fill digits backwards ...
//     if (v < 0) *--p = '-';
//     write(1, p, end - p);
//
// The '-' is stored in front of the digits, so there is still one write.

    .global _main

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_main:
    mov x19, #-12345            // try 678 and 0 too

    // ---- print x19 as a signed decimal, followed by a newline ----
    adrp x1, numbuf@PAGE
    add x1, x1, numbuf@PAGEOFF
    add x5, x1, #32             // x5 = end of buffer
    mov x1, x5                  // x1 = p
    mov w2, #10
    strb w2, [x1, #-1]!         // *--p = '\n'
    mov x2, x19
    cmp x19, #0
    cneg x2, x2, lt             // n = |v|
    mov x3, #10
digit:
    udiv x4, x2, x3
    msub x6, x4, x3, x2
    add w6, w6, #'0'
    strb w6, [x1, #-1]!
    mov x2, x4
    cbnz x2, digit
    cmp x19, #0
    b.ge no_sign
    mov w2, #'-'
    strb w2, [x1, #-1]!         // *--p = '-'
no_sign:
    mov x0, #1
    sub x2, x5, x1
    mov x16, #4                 // 4 = write
    svc #0x80
    // ---- end of print ----

    mov x0, #0
    mov x16, #1                 // 1 = exit
    svc #0x80
