// bytesum.s - walk a byte array with a post-index load.
//
// Build:  make
// Run:    ./bytesum; echo $?
// Expect: exit status 36 (1 + 2 + ... + 8)
//
// C equivalent:
//     unsigned char data[8] = {1, 2, 3, 4, 5, 6, 7, 8};
//     unsigned char *p = data;
//     int sum = 0;
//     for (int n = 8; n != 0; n--)
//         sum += *p++;

    .global _main

    .data
data:
    .byte 1, 2, 3, 4, 5, 6, 7, 8

    .text
    .p2align 2

_main:
    adrp x1, data@PAGE
    add x1, x1, data@PAGEOFF    // x1 = p = address of data[0]
    mov x2, #8                  // x2 = n, bytes left
    mov x0, #0                  // x0 = sum
loop:
    ldrb w3, [x1], #1           // w3 = *p; then p = p + 1
    add x0, x0, x3              // sum += that byte
    sub x2, x2, #1              // n--
    cbnz x2, loop               // keep going while n != 0
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(sum)
