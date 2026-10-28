// ex4.s - Exercise 00.4: prints "I built this myself!" and exits with status 0 (macOS version).
//
// You are NOT expected to understand this file yet. You will understand
// every line of it by the end of lesson 05. For now, just build and run it.
//
// Build:  make
// Run:    ./ex4
// Output: I built this myself!
// Exit status (echo $?): 0

    .global _main               // make _main visible to the linker (lesson 04)

    .text                       // what follows is code (lesson 04)
    .p2align 2                  // start on a 4-byte boundary (lesson 04)
_main:                          // the program starts running here (lesson 04)
    mov x0, #1                  // x0 = 1: file descriptor 1 is the screen (lesson 05)
    adrp x1, msg@PAGE           // x1 = address of msg, part 1 (lesson 05)
    add x1, x1, msg@PAGEOFF     // x1 = address of msg, part 2 (lesson 05)
    mov x2, #len                // x2 = number of bytes to print (lesson 05)
    mov x16, #4                 // 4 is the macOS number for "write" (lesson 05)
    svc #0x80                   // ask the kernel to do it (lesson 04)

    mov x0, #0                  // x0 = 0: exit status (lesson 04)
    mov x16, #1                 // 1 is the macOS number for "exit" (lesson 04)
    svc #0x80                   // ask the kernel to end the program (lesson 04)

    .data                       // what follows is data (lesson 05)
msg:
    .ascii "I built this myself!\n"   // the bytes to print (changed)
    .equ len, . - msg           // len = how many bytes that was (lesson 05)
