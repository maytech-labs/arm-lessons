// bubble.s - bubble sort an int array, then print it.
//
// Build:  make
// Run:    ./bubble
// Expect: 1 2 3 4 5 6 7 8 9 10
//
// C equivalent:
//     int a[10] = {7, 3, 10, 1, 9, 2, 8, 5, 4, 6};
//     for (long end = N - 1; end > 0; end--)        // after each pass the
//         for (long i = 0; i < end; i++)            // biggest is at a[end]
//             if (a[i] > a[i+1]) { int t = a[i]; a[i] = a[i+1]; a[i+1] = t; }

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
    mov x10, #N - 1             // x10 = end
outer:
    cbz x10, sorted             // for (end = N-1; end > 0; end--)
    mov x11, #0                 // x11 = i
inner:
    cmp x11, x10
    b.ge next_pass              // for (i = 0; i < end; i++)
    add x12, x9, x11, lsl #2    // x12 = &a[i]
    ldp w13, w14, [x12]         // w13 = a[i], w14 = a[i+1]
    cmp w13, w14
    b.le no_swap                // signed: already in order
    stp w14, w13, [x12]         // swap them back in the other order
no_swap:
    add x11, x11, #1
    b inner
next_pass:
    sub x10, x10, #1
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
