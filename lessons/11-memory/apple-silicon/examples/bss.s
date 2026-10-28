// bss.s - fill a buffer in .bss with the alphabet, then write it.
//
// Build:  make
// Run:    ./bss
// Expect: ABCDEFGHIJKLMNOPQRSTUVWXYZ
//
// C equivalent:
//     char buf[27];              // a global with no initial value: in .bss
//     for (char c = 'A'; c <= 'Z'; c++) buf[c - 'A'] = c;
//     buf[26] = '\n';
//     write(1, buf, 27);

    .global _main

    .bss                        // zero-filled at startup, takes no file space
buf:
    .space 27                   // reserve 27 bytes

    .text
    .p2align 2

_main:
    adrp x1, buf@PAGE
    add x1, x1, buf@PAGEOFF     // x1 = &buf[0]
    mov x2, x1                  // x2 = p, where the next letter goes
    mov w3, #'A'                // w3 = c
fill:
    strb w3, [x2], #1           // *p++ = c
    add w3, w3, #1              // c++
    cmp w3, #'Z'
    b.ls fill                   // while (c <= 'Z')
    mov w3, #10                 // '\n'
    strb w3, [x2]               // buf[26] = '\n'

    mov x0, #1                  // fd 1 = stdout
                                // x1 is still &buf[0]
    mov x2, #27                 // 27 bytes
    mov x16, #4                 // 4 = write
    svc #0x80

    mov x0, #0
    mov x16, #1                 // 1 = exit
    svc #0x80
