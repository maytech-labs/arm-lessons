// ex5.s - count the 'l' characters in a string.
//
// Build:  make
// Run:    ./ex5; echo $?
// Expect: exit status 3
//
// C equivalent:
//     const char *p = "hello, world\n";
//     int count = 0;
//     for (long n = LEN; n != 0; n--)
//         if (*p++ == 'l') count++;
//     return count;

    .global _main

    .data
msg:
    .ascii "hello, world\n"
    .equ LEN, 13

    .text
    .p2align 2

_main:
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF     // x1 = p
    mov x2, #LEN                // x2 = bytes left
    mov x0, #0                  // x0 = count
loop:
    cbz x2, done                // no bytes left: finished
    ldrb w3, [x1], #1           // w3 = *p++
    sub x2, x2, #1
    cmp w3, #'l'
    cinc x0, x0, eq             // count += (c == 'l')
    b loop
done:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(count)
