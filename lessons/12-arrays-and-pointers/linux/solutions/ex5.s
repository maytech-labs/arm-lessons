// ex5.s - Exercise 12.5: copy a into b in reverse order, then print b.
//
// C:      int a[8] = {1, 2, 3, 4, 5, 6, 7, 8}, b[8];
//         int *src = a, *dst = b + 8;
//         for (long i = 0; i < 8; i++) *--dst = *src++;
//         print(b);
// Build:  make
// Run:    ./ex5
// Expected output:
//   8 7 6 5 4 3 2 1
//
// The print block prints the array at label a, so the destination is named a
// here and the source is named src.

    .global _start

    .data
src:
    .word 1, 2, 3, 4, 5, 6, 7, 8
    .equ N, (. - src) / 4
a:  .space N * 4                // the destination: N ints, zero to start

    .bss
numbuf:
    .space 32

    .text
    .p2align 2
_start:
    adrp x9, src
    add x9, x9, :lo12:src       // x9 = source pointer, walks forwards
    adrp x10, a
    add x10, x10, :lo12:a
    mov x11, #N * 4             // sizeof the destination, in bytes
    add x10, x10, x11           // x10 = one past the end of the destination
    mov x12, #N                 // elements left
copy:
    ldr w13, [x9], #4           // w13 = *src++   (post-index: use, then move)
    str w13, [x10, #-4]!        // *--dst = w13   (pre-index: move, then use)
    subs x12, x12, #1
    b.ne copy
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
    mov x8, #93                 // exit(0)
    svc #0
