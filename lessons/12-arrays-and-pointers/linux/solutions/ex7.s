// ex7.s - Exercise 12.7: selection sort of a long array.
//
// C:      long a[8] = {50, 20, 70, 10, 80, 30, 60, 40};
//         for (long i = 0; i < N - 1; i++) {
//             long min = i;
//             for (long j = i + 1; j < N; j++) if (a[j] < a[min]) min = j;
//             long t = a[i]; a[i] = a[min]; a[min] = t;
//         }
// Build:  make
// Run:    ./ex7
// Expected output:
//   10 20 30 40 50 60 70 80
//
// The array holds longs (8 bytes), so the index scale is lsl #3. The print
// block below was written for ints: it uses lsl #3 and ldr here as well.

    .global _start

    .data
a:  .quad 50, 20, 70, 10, 80, 30, 60, 40
    .equ N, (. - a) / 8

    .bss
numbuf:
    .space 32

    .text
    .p2align 2
_start:
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a
    mov x10, #0                 // x10 = i
    mov x15, #N                 // x15 = N
    sub x16, x15, #1            // x16 = N - 1
outer:
    cmp x10, x16
    b.ge sorted                 // for (i = 0; i < N - 1; i++)
    mov x11, x10                // x11 = min = i
    add x12, x10, #1            // x12 = j = i + 1
inner:
    cmp x12, x15
    b.ge swap
    ldr x13, [x9, x12, lsl #3]  // a[j]
    ldr x14, [x9, x11, lsl #3]  // a[min]
    cmp x13, x14
    csel x11, x12, x11, lt      // if (a[j] < a[min]) min = j
    add x12, x12, #1
    b inner
swap:
    ldr x13, [x9, x10, lsl #3]  // t = a[i]
    ldr x14, [x9, x11, lsl #3]  // a[min]
    str x14, [x9, x10, lsl #3]  // a[i] = a[min]
    str x13, [x9, x11, lsl #3]  // a[min] = t
    add x10, x10, #1
    b outer
sorted:
    // ---- print the array: N ints at a, separated by spaces ----
    mov x21, #0                 // x21 = i
    mov x15, #N                 // x15 = N (the print block leaves x15 alone)
print_loop:
    adrp x9, a
    add x9, x9, :lo12:a
    ldr x19, [x9, x21, lsl #3]  // x19 = a[i] (a long)
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
    mov x8, #93                 // exit(0)
    svc #0
