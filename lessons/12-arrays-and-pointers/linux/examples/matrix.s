// matrix.s - a 2D int array in row-major order: m[r][c].
//
// Build:  make
// Run:    ./matrix
// Expect: 7
//         10 26 42
//
// C equivalent:
//     int m[3][4] = { { 1,  2,  3,  4},
//                     { 5,  6,  7,  8},
//                     { 9, 10, 11, 12} };
//     print(m[1][2]);
//     for (long r = 0; r < 3; r++) {
//         long sum = 0;
//         for (long c = 0; c < 4; c++) sum += m[r][c];
//         print(sum);
//     }

    .global _start

    .equ ROWS, 3
    .equ COLS, 4

    .data
    .p2align 2
m:  .word  1,  2,  3,  4        // row 0
    .word  5,  6,  7,  8        // row 1
    .word  9, 10, 11, 12        // row 2

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    // ---- m[1][2]: element number 1*COLS + 2 = 6, at byte offset 24 ----
    adrp x9, m
    add x9, x9, :lo12:m         // x9 = m
    mov x10, #1                 // r = 1
    mov x11, #2                 // c = 2
    mov x13, #COLS
    madd x12, x10, x13, x11     // x12 = r * COLS + c
    ldrsw x19, [x9, x12, lsl #2]    // x19 = m[r][c]
    mov w20, #10
    // ---- print x19 in decimal, followed by the character in w20 ----
    adrp x1, numbuf
    add x1, x1, :lo12:numbuf
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
    mov x8, #64                 // 64 = write
    svc #0
    // ---- end of print ----

    // ---- the sum of each row ----
    mov x21, #0                 // x21 = r
row:
    mov x23, #0                 // x23 = sum
    mov x22, #0                 // x22 = c
col:
    adrp x9, m
    add x9, x9, :lo12:m
    mov x13, #COLS
    madd x12, x21, x13, x22     // x12 = r * COLS + c
    ldrsw x14, [x9, x12, lsl #2]    // x14 = m[r][c]
    add x23, x23, x14
    add x22, x22, #1
    cmp x22, #COLS
    b.lo col

    mov x19, x23
    mov w20, #' '
    mov w9, #10
    cmp x21, #ROWS - 1
    csel w20, w9, w20, eq
    // ---- print x19 in decimal, followed by the character in w20 ----
    adrp x1, numbuf
    add x1, x1, :lo12:numbuf
    add x5, x1, #32             // x5 = end of buffer
    mov x1, x5                  // x1 = p
    strb w20, [x1, #-1]!        // *--p = separator (' ' or '\n')
    mov x2, x19                 // x2 = n
    mov x3, #10
digit2:
    udiv x4, x2, x3             // x4 = n / 10
    msub x6, x4, x3, x2         // x6 = n % 10
    add w6, w6, #'0'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x2, x4
    cbnz x2, digit2
    mov x0, #1                  // fd 1 = stdout
    sub x2, x5, x1              // length = end - p
    mov x8, #64                 // 64 = write
    svc #0
    // ---- end of print ----
    add x21, x21, #1
    cmp x21, #ROWS
    b.lo row

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
