// insertion.s - insertion sort an int array, then print it.
//
// Build:  make
// Run:    ./insertion
// Expect: 1 2 3 4 5 6 7 8 9 10
//
// C equivalent:
//     int a[10] = {7, 3, 10, 1, 9, 2, 8, 5, 4, 6};
//     for (long i = 1; i < N; i++) {
//         int key = a[i];
//         long j = i - 1;
//         while (j >= 0 && a[j] > key) {   // shift bigger ones right
//             a[j+1] = a[j];
//             j--;
//         }
//         a[j+1] = key;
//     }

    .global _main

    .data
    .p2align 2
a:  .word 7, 3, 10, 1, 9, 2, 8, 5, 4, 6
    .equ N, (. - a) / 4

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_main:
    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF       // x9 = a
    mov x10, #1                 // x10 = i
    mov x15, #N                 // x15 = N
outer:
    cmp x10, x15
    b.ge sorted
    ldr w11, [x9, x10, lsl #2]  // w11 = key = a[i]
    sub x12, x10, #1            // x12 = j = i - 1 (signed: can reach -1)
shift:
    tbnz x12, #63, place        // j < 0 (sign bit set): stop
    ldr w13, [x9, x12, lsl #2]  // w13 = a[j]
    cmp w13, w11
    b.le place                  // a[j] <= key: stop
    add x14, x12, #1
    str w13, [x9, x14, lsl #2]  // a[j+1] = a[j]
    sub x12, x12, #1            // j--
    b shift
place:
    add x14, x12, #1
    str w11, [x9, x14, lsl #2]  // a[j+1] = key
    add x10, x10, #1
    b outer
sorted:

    // ---- print the array: N ints at a, separated by spaces ----
    mov x21, #0                 // x21 = i
    mov x15, #N                 // x15 = N (the print block leaves x15 alone)
print_loop:
    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF
    ldrsw x19, [x9, x21, lsl #2]    // x19 = a[i]
    add x9, x21, #1             // x9 = i + 1
    mov w20, #' '               // separator: a space...
    mov w10, #10
    cmp x9, x15
    csel w20, w10, w20, eq      // ...or '\n' after the last element
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
    add x21, x21, #1            // i++
    cmp x21, x15
    b.lo print_loop             // while (i < N)

    mov x0, #0
    mov x16, #1                 // 1 = exit
    svc #0x80
