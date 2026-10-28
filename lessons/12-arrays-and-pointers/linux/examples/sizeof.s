// sizeof.s - let the assembler count the bytes and elements of arrays.
//
// Build:  make
// Run:    ./sizeof
// Expect: 32 8 40 5
//
// C equivalent:
//     int  a[] = {3, 1, 4, 1, 5, 9, 2, 6};
//     long b[] = {10, 20, 30, 40, 50};
//     long sizes[4] = { sizeof a, sizeof a / sizeof a[0],
//                       sizeof b, sizeof b / sizeof b[0] };
//     for (long i = 0; i < 4; i++) print(sizes[i]);

    .global _start

    .data
    .p2align 2
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
    .equ A_BYTES, . - a         // "." is the current address: the end of a
    .equ A_LEN, A_BYTES / 4

    .p2align 3
b:  .quad 10, 20, 30, 40, 50
    .equ B_BYTES, . - b
    .equ B_LEN, B_BYTES / 8

sizes:                          // the assembler fills in the numbers
    .quad A_BYTES, A_LEN, B_BYTES, B_LEN

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    mov x21, #0                 // x21 = i
next:
    adrp x9, sizes
    add x9, x9, :lo12:sizes
    ldr x19, [x9, x21, lsl #3]  // x19 = sizes[i]
    mov w20, #' '               // separator: a space...
    mov w9, #10
    cmp x21, #3
    csel w20, w9, w20, eq       // ...or '\n' after the last one
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
    add x21, x21, #1
    cmp x21, #4
    b.lo next

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
