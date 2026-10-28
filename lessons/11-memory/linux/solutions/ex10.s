// ex10.s - print x19 in hexadecimal: "0x" and exactly 16 digits.
//
// Build:  make
// Run:    ./ex10
// Expect: 0x00000000deadbeef
//
// C equivalent:
//     static const char hex[16] = "0123456789abcdef";
//     char buf[19], *p = buf + 19;
//     *--p = '\n';
//     for (int i = 0; i < 16; i++) { *--p = hex[n & 15]; n >>= 4; }
//     *--p = 'x'; *--p = '0';
//     write(1, p, 19);

    .global _start

    .data
hexdigits:
    .ascii "0123456789abcdef"

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    movz x19, #0xdead, lsl #16
    movk x19, #0xbeef           // x19 = 0xdeadbeef

    adrp x7, hexdigits
    add x7, x7, :lo12:hexdigits   // x7 = the table
    adrp x1, numbuf
    add x1, x1, :lo12:numbuf
    add x5, x1, #32             // x5 = end of buffer
    mov x1, x5                  // x1 = p
    mov w2, #10
    strb w2, [x1, #-1]!         // *--p = '\n'
    mov x2, x19                 // n
    mov x3, #16                 // 16 digits to produce
hex_digit:
    and x4, x2, #0xf            // the lowest 4 bits
    ldrb w6, [x7, x4]           // w6 = hexdigits[n & 15]
    strb w6, [x1, #-1]!         // *--p = digit
    lsr x2, x2, #4              // n >>= 4
    sub x3, x3, #1
    cbnz x3, hex_digit
    mov w2, #'x'
    strb w2, [x1, #-1]!
    mov w2, #'0'
    strb w2, [x1, #-1]!
    mov x0, #1
    sub x2, x5, x1              // 19 bytes
    mov x8, #64                 // 64 = write
    svc #0

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
