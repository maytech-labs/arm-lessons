// echo.s - read up to 64 bytes from standard input and write them back.
//
// Build:  make
// Run:    echo hello | ./echo
//         ./echo              (type a line and press Enter)
// Expect: the same text back, e.g. "hello". Exit status = bytes read.

    .global _main

    .bss
buf:
    .space 64

    .text
    .p2align 2

_main:
    mov x0, #0                  // fd 0 = stdin
    adrp x1, buf@PAGE
    add x1, x1, buf@PAGEOFF     // where to put the bytes
    mov x2, #64                 // at most 64 of them
    mov x16, #3                 // 3 = read
    svc #0x80                   // x0 = number of bytes actually read

    mov x19, x0                 // keep the count safe in x19
    mov x2, x0                  // write exactly as many bytes as we read
    mov x0, #1                  // fd 1 = stdout
    adrp x1, buf@PAGE           // load the buffer address again: do not
    add x1, x1, buf@PAGEOFF     // count on x1 surviving a system call
    mov x16, #4                 // 4 = write
    svc #0x80

    mov x0, x19                 // exit status = bytes read
    mov x16, #1                 // 1 = exit
    svc #0x80
