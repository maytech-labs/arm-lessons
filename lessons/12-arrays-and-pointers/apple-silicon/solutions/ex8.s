// ex8.s - Exercise 12.8: remove duplicates from a sorted array, in place (macOS).
//
// C:      int a[] = {1, 1, 2, 3, 3, 3, 4, 5, 5};
//         long k = 1;                       // a[0..k-1] holds the unique values
//         for (long i = 1; i < 9; i++)
//             if (a[i] != a[k - 1]) a[k++] = a[i];
//         print(a[0..k-1]); return k;
// Build:  make
// Run:    ./ex8; echo $?
// Expected output:
//   1 2 3 4 5
// Exit status (echo $?): 5

    .global _main

    .data
a:  .word 1, 1, 2, 3, 3, 3, 4, 5, 5
    .equ N, (. - a) / 4

    .bss
numbuf:
    .space 32

    .text
    .p2align 2
_main:
    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF       // x9 = a
    mov x15, #1                 // x15 = k
    mov x10, #1                 // x10 = i
    mov x16, #N                 // x16 = N
loop:
    cmp x10, x16
    b.ge done
    ldr w11, [x9, x10, lsl #2]  // a[i]
    sub x12, x15, #1
    ldr w12, [x9, x12, lsl #2]  // a[k - 1]
    cmp w11, w12
    b.eq next                   // a duplicate: skip it
    str w11, [x9, x15, lsl #2]  // a[k] = a[i]
    add x15, x15, #1            // k++
next:
    add x10, x10, #1
    b loop
done:
    mov x24, x15                // keep k for the exit status
    // ---- print the array: N ints at a, separated by spaces ----
    mov x21, #0                 // x21 = i
                                // x15 = k: print only a[0..k-1]
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

    mov x0, x24                 // exit(k)
    mov x16, #1
    svc #0x80
