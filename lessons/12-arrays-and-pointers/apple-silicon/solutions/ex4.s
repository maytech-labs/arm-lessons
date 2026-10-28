// ex4.s - Exercise 12.4: the dot product of two int arrays (macOS).
//
// C:      int a[4] = {1, 2, 3, 4}, b[4] = {5, 6, 7, 8};
//         long dot = 0;
//         for (long i = 0; i < 4; i++) dot += a[i] * b[i];
//         print(dot);
// Build:  make
// Run:    ./ex4
// Expected output:
//   70

    .global _main

    .data
a:  .word 1, 2, 3, 4
    .equ N, (. - a) / 4
b:  .word 5, 6, 7, 8

    .bss
numbuf:
    .space 32

    .text
    .p2align 2
_main:
    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF       // x9 = p = a
    adrp x10, b@PAGE
    add x10, x10, b@PAGEOFF     // x10 = q = b
    mov x12, #N                 // x12 = elements left
    mov x19, #0                 // x19 = dot
loop:
    ldrsw x13, [x9], #4         // x13 = *p++
    ldrsw x14, [x10], #4        // x14 = *q++
    madd x19, x13, x14, x19     // dot += a[i] * b[i]
    subs x12, x12, #1
    b.ne loop                   // N is never 0 here, so no guard is needed
    mov w20, #10
    // ---- print x19 in decimal, followed by the character in w20 ----
    adrp x1, numbuf@PAGE
    add x1, x1, numbuf@PAGEOFF
    add x5, x1, #32             // x5 = end of buffer
    mov x1, x5                  // x1 = p
    strb w20, [x1, #-1]!        // *--p = separator (' ' or '\n')
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
    mov x16, #1                 // exit(0)
    svc #0x80
