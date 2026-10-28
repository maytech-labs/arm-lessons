// sum_index.s - add up an int array using an index: a[i].
//
// Build:  make
// Run:    ./sum_index
// Expect: 31
//
// C equivalent:
//     int a[8] = {3, 1, 4, 1, 5, 9, 2, 6};
//     long sum = 0;
//     for (long i = 0; i < 8; i++)
//         sum += a[i];
//     print(sum);

    .global _start

    .data
    .p2align 2                  // int is 4 bytes: align to 4
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
    .equ N, (. - a) / 4         // number of elements: bytes / sizeof(int)

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a (address of a[0])
    mov x10, #0                 // x10 = i
    mov x19, #0                 // x19 = sum
    mov x15, #N                 // x15 = N
loop:
    cmp x10, x15
    b.ge done                   // while (i < N)
    ldrsw x11, [x9, x10, lsl #2]    // x11 = a[i]: address a + i*4
    add x19, x19, x11           // sum += a[i]
    add x10, x10, #1            // i++
    b loop
done:
    mov w20, #10                // print sum, then '\n'
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
    mov x8, #93                 // 93 = exit
    svc #0
