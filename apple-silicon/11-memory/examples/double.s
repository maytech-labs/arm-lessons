// double.s - read a decimal number from stdin, double it, print the result.
//
// Build:  make
// Run:    echo 21 | ./double
// Expect: 42
//         (echo 0 | ./double prints 0; echo 1000000 | ./double prints 2000000)
//
// C equivalent:
//     char in[32];
//     long len = read(0, in, 32);
//     unsigned long n = 0;
//     for (char *p = in; len > 0; len--) {
//         unsigned d = *p++ - '0';
//         if (d > 9) break;             // not a digit: stop
//         n = n * 10 + d;
//     }
//     n = n * 2;
//     ... print n exactly as in printnum.s ...

    .global _main

    .bss
inbuf:
    .space 32
numbuf:
    .space 32

    .text
    .p2align 2

_main:
    // ---- read a line ----
    mov x0, #0                  // fd 0 = stdin
    adrp x1, inbuf@PAGE
    add x1, x1, inbuf@PAGEOFF
    mov x2, #32
    mov x16, #3                 // 3 = read
    svc #0x80                   // x0 = bytes read (0 at end of input)
    adrp x1, inbuf@PAGE         // reload the address: only x0 is safe
    add x1, x1, inbuf@PAGEOFF   // to rely on after a system call

    // ---- parse decimal digits: x19 = value ----
    mov x19, #0                 // n = 0
    mov x3, #10
parse:
    cbz x0, parsed              // no bytes left
    ldrb w2, [x1], #1           // w2 = *p++
    sub w2, w2, #'0'            // '0'..'9' -> 0..9; anything else -> other
    cmp w2, #9
    b.hi parsed                 // unsigned > 9: not a digit (newline, etc.)
    madd x19, x19, x3, x2       // n = n * 10 + d
    sub x0, x0, #1              // len--
    b parse
parsed:

    add x19, x19, x19           // n = n * 2

    // ---- print x19 in decimal, followed by a newline ----
    adrp x1, numbuf@PAGE
    add x1, x1, numbuf@PAGEOFF
    add x5, x1, #32             // x5 = end of buffer
    mov x1, x5                  // x1 = p
    mov w2, #10                 // '\n'
    strb w2, [x1, #-1]!         // *--p = '\n'
    mov x2, x19                 // x2 = n
    mov x3, #10
digit:
    udiv x4, x2, x3             // x4 = n / 10
    msub x6, x4, x3, x2         // x6 = n % 10
    add w6, w6, #'0'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x2, x4
    cbnz x2, digit
    mov x0, #1                  // fd 1 = stdout
    sub x2, x5, x1              // length = end - p
    mov x16, #4                 // 4 = write
    svc #0x80
    // ---- end of print ----

    mov x0, #0
    mov x16, #1                 // 1 = exit
    svc #0x80
