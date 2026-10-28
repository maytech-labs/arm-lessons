// ex3.s - Exercise 12.3: count the negative elements of an int array.
//
// C:      int a[8] = {3, -1, 4, -1, -5, 9, 2, -6};
//         long count = 0;
//         for (long i = 0; i < 8; i++) if (a[i] < 0) count++;
//         print(count);
// Build:  make
// Run:    ./ex3
// Expected output:
//   4

    .global _start

    .data
a:  .word 3, -1, 4, -1, -5, 9, 2, -6
    .equ N, (. - a) / 4

    .bss
numbuf:
    .space 32

    .text
    .p2align 2
_start:
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a
    mov x10, #0                 // x10 = i
    mov x19, #0                 // x19 = count
    mov x15, #N                 // x15 = N
loop:
    cmp x10, x15
    b.ge done                   // for (i = 0; i < N; i++)
    ldrsw x11, [x9, x10, lsl #2]    // x11 = a[i], sign-extended: negatives stay negative
    cmp x11, #0
    cinc x19, x19, lt           // if (a[i] < 0) count++
    add x10, x10, #1
    b loop
done:
    mov w20, #10                // print count, then '\n'
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

    mov x0, #0
    mov x8, #93                 // exit(0)
    svc #0
