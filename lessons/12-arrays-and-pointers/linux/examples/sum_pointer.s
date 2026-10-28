// sum_pointer.s - add up the same int array by walking a pointer: *p++.
//
// Build:  make
// Run:    ./sum_pointer
// Expect: 31
//
// C equivalent:
//     int a[8] = {3, 1, 4, 1, 5, 9, 2, 6};
//     long sum = 0;
//     for (int *p = a, *end = a + 8; p != end; p++)
//         sum += *p;
//     print(sum);

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
    add x9, x9, :lo12:a         // x9 = p = a
    mov x10, #N * 4             // x10 = sizeof a = N * 4 bytes
    add x10, x9, x10            // x10 = end = a + N (N*4 bytes along)
    mov x19, #0                 // x19 = sum
loop:
    cmp x9, x10
    b.eq done                   // while (p != end)
    ldrsw x11, [x9], #4         // x11 = *p, then p++ (4 bytes)
    add x19, x19, x11
    b loop
done:
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

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
