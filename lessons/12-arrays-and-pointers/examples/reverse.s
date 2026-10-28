// reverse.s - reverse an int array in place with two pointers, then print it.
//
// Build:  make
// Run:    ./reverse
// Expect: 6 2 9 5 1 4 1 3
//
// C equivalent:
//     int a[8] = {3, 1, 4, 1, 5, 9, 2, 6};
//     int *lo = a, *hi = a + 8 - 1;
//     while (lo < hi) {
//         int t = *lo; *lo = *hi; *hi = t;
//         lo++; hi--;
//     }
//     for (long i = 0; i < 8; i++) print(a[i]);

    .global _start

    .data
    .p2align 2
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
    .equ N, (. - a) / 4

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a
    mov x10, x9                 // x10 = lo = &a[0]
    mov x11, #(N - 1) * 4
    add x11, x9, x11            // x11 = hi = &a[N-1]
swap:
    cmp x10, x11
    b.hs reversed               // while (lo < hi): pointers are unsigned
    ldr w12, [x10]              // w12 = *lo
    ldr w13, [x11]              // w13 = *hi
    str w13, [x10], #4          // *lo = old *hi, lo++
    str w12, [x11], #-4         // *hi = old *lo, hi--
    b swap
reversed:

    // ---- print the array: N ints at a, separated by spaces ----
    mov x21, #0                 // x21 = i
    mov x15, #N                 // x15 = N (the print block leaves x15 alone)
print_loop:
    adrp x9, a
    add x9, x9, :lo12:a
    ldrsw x19, [x9, x21, lsl #2]    // x19 = a[i]
    add x9, x21, #1             // x9 = i + 1
    mov w20, #' '               // separator: a space...
    mov w10, #10
    cmp x9, x15
    csel w20, w10, w20, eq      // ...or '\n' after the last element
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
    add x21, x21, #1            // i++
    cmp x21, x15
    b.lo print_loop             // while (i < N)

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
