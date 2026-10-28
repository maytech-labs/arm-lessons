// ex6.s - Exercise 12.6: the sum of each COLUMN of a 3x4 matrix (macOS).
//
// C:      int m[3][4] = {{1,2,3,4}, {5,6,7,8}, {9,10,11,12}};
//         for (long c = 0; c < 4; c++) {
//             long sum = 0;
//             for (long r = 0; r < 3; r++) sum += m[r][c];
//             print(sum);
//         }
// Build:  make
// Run:    ./ex6
// Expected output:
//   15 18 21 24

    .global _main

    .data
    .equ ROWS, 3
    .equ COLS, 4
m:  .word  1,  2,  3,  4
    .word  5,  6,  7,  8
    .word  9, 10, 11, 12

    .bss
numbuf:
    .space 32

    .text
    .p2align 2
_main:
    mov x21, #0                 // x21 = c
col:
    adrp x9, m@PAGE
    add x9, x9, m@PAGEOFF
    add x9, x9, x21, lsl #2     // x9 = &m[0][c]
    mov x22, #ROWS              // rows left
    mov x23, #0                 // x23 = sum
row:
    ldrsw x14, [x9], #COLS * 4  // sum += m[r][c]; then step one whole row down
    add x23, x23, x14
    subs x22, x22, #1
    b.ne row
    mov x19, x23
    mov w20, #' '               // separator: a space...
    mov w9, #10
    cmp x21, #COLS - 1
    csel w20, w9, w20, eq       // ...or '\n' after the last column
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
    add x21, x21, #1
    cmp x21, #COLS
    b.lo col

    mov x0, #0
    mov x16, #1                 // exit(0)
    svc #0x80
