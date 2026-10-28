// maxmin.s - largest and smallest element of a long array, with csel.
//
// Build:  make
// Run:    ./maxmin
// Expect: 97 4
//
// C equivalent:
//     long a[10] = {42, 17, 97, 8, 55, 4, 63, 21, 90, 36};
//     long max = a[0], min = a[0];
//     for (long i = 1; i < 10; i++) {
//         if (a[i] > max) max = a[i];
//         if (a[i] < min) min = a[i];
//     }
//     print(max, min);

    .global _start

    .data
    .p2align 3                  // long is 8 bytes: align to 8
a:  .quad 42, 17, 97, 8, 55, 4, 63, 21, 90, 36
    .equ N, (. - a) / 8

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a
    ldr x21, [x9]               // x21 = max = a[0]
    mov x22, x21                // x22 = min = a[0]
    mov x10, #1                 // x10 = i
    mov x15, #N                 // x15 = N
loop:
    cmp x10, x15
    b.ge done
    ldr x11, [x9, x10, lsl #3]  // x11 = a[i]: address a + i*8
    cmp x11, x21
    csel x21, x11, x21, gt      // max = a[i] > max ? a[i] : max   (signed)
    cmp x11, x22
    csel x22, x11, x22, lt      // min = a[i] < min ? a[i] : min
    add x10, x10, #1
    b loop
done:
    mov x19, x21                // print max...
    mov w20, #' '
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
    mov x19, x22                // ...then min (a second copy of the block)
    mov w20, #10
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

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
