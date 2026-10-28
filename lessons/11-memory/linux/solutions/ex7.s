// ex7.s - print 1 to 10, one per line.
//
// Build:  make
// Run:    ./ex7
// Expect: the numbers 1 to 10, each on its own line
//
// C equivalent:
//     for (unsigned long i = 1; i <= 10; i++)
//         print i and a newline;

    .global _start

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    mov x19, #1                 // i = 1 (x19 is not touched by the print block)
next_number:

    // ---- print x19 in decimal, followed by a newline ----
    adrp x1, numbuf
    add x1, x1, :lo12:numbuf
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
    mov x8, #64                 // 64 = write
    svc #0
    // ---- end of print ----

    add x19, x19, #1            // i++
    cmp x19, #10
    b.ls next_number            // while (i <= 10)

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
