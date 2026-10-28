// bsearch.s - binary search a sorted array for a number read from stdin.
//
// Build:  make
// Run:    echo 23 | ./bsearch
// Expect: 6   (the index of 23)
//         echo 24 | ./bsearch prints "not found"
//
// C equivalent:
//     int a[12] = {2, 3, 5, 7, 11, 13, 23, 29, 31, 37, 41, 43};
//     long lo = 0, hi = N - 1;
//     while (lo <= hi) {
//         long mid = (lo + hi) / 2;
//         if (a[mid] == key) { print(mid); return 0; }
//         if (a[mid] < key) lo = mid + 1;
//         else              hi = mid - 1;
//     }
//     write "not found";

    .global _start

    .data
    .p2align 2
a:  .word 2, 3, 5, 7, 11, 13, 23, 29, 31, 37, 41, 43
    .equ N, (. - a) / 4
notfound:
    .ascii "not found\n"

    .bss
inbuf:
    .space 32
numbuf:
    .space 32

    .text
    .p2align 2

_start:
    // ---- read and parse the key into x22 ----
    mov x0, #0
    adrp x1, inbuf
    add x1, x1, :lo12:inbuf
    mov x2, #32
    mov x8, #63                 // 63 = read
    svc #0
    adrp x1, inbuf
    add x1, x1, :lo12:inbuf
    mov x22, #0
    mov x3, #10
parse:
    cbz x0, parsed
    ldrb w2, [x1], #1
    sub w2, w2, #'0'
    cmp w2, #9
    b.hi parsed
    madd x22, x22, x3, x2
    sub x0, x0, #1
    b parse
parsed:

    // ---- binary search ----
    adrp x9, a
    add x9, x9, :lo12:a         // x9 = a
    mov x10, #0                 // x10 = lo
    mov x11, #N - 1             // x11 = hi
search:
    cmp x10, x11
    b.gt missing                // while (lo <= hi), signed: hi can be -1
    add x12, x10, x11
    lsr x12, x12, #1            // x12 = mid = (lo + hi) / 2
    ldrsw x13, [x9, x12, lsl #2]    // x13 = a[mid]
    cmp x13, x22
    b.eq found
    b.lt go_right
    sub x11, x12, #1            // a[mid] > key: hi = mid - 1
    b search
go_right:
    add x10, x12, #1            // a[mid] < key: lo = mid + 1
    b search

found:
    mov x19, x12
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
    b exit

missing:
    mov x0, #1
    adrp x1, notfound
    add x1, x1, :lo12:notfound
    mov x2, #10
    mov x8, #64                 // 64 = write
    svc #0
exit:
    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
