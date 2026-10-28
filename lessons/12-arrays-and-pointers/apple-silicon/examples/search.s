// search.s - linear search with a pointer; the index is a pointer difference.
//
// Build:  make
// Run:    ./search; echo $?
// Expect: 4  (printed, and also the exit status)
//
// C equivalent:
//     int a[8] = {3, 1, 4, 1, 5, 9, 2, 6};
//     int key = 5;
//     int *p = a, *end = a + 8;
//     while (p != end && *p != key) p++;
//     if (p == end) { write "not found"; return 255; }
//     long index = p - a;           // C divides the byte distance by 4
//     print(index); return index;

    .global _main

    .data
    .p2align 2
a:  .word 3, 1, 4, 1, 5, 9, 2, 6
    .equ N, (. - a) / 4
    .equ KEY, 5

notfound:
    .ascii "not found\n"

    .bss
numbuf:
    .space 32

    .text
    .p2align 2

_main:
    adrp x9, a@PAGE
    add x9, x9, a@PAGEOFF       // x9 = a
    mov x10, x9                 // x10 = p
    mov x11, #N * 4
    add x11, x9, x11            // x11 = end = a + N
loop:
    cmp x10, x11
    b.eq missing                // ran off the end
    ldr w12, [x10]              // w12 = *p
    cmp w12, #KEY
    b.eq found
    add x10, x10, #4            // p++
    b loop

found:
    sub x19, x10, x9            // bytes between p and a
    lsr x19, x19, #2            // / sizeof(int): index = p - a
    mov w20, #10
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
    mov x0, x19                 // exit status = index
    b exit

missing:
    mov x0, #1
    adrp x1, notfound@PAGE
    add x1, x1, notfound@PAGEOFF
    mov x2, #10
    mov x16, #4                 // 4 = write
    svc #0x80
    mov x0, #255
exit:
    mov x16, #1                 // 1 = exit
    svc #0x80
