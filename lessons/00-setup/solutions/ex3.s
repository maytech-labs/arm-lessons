// ex3.s - Exercise 00.3: prints "toolchain works" and exits with status 7.
//
// You are NOT expected to understand this file yet. You will understand
// every line of it by the end of lesson 05. For now, just build and run it.
//
// Build:  make
// Run:    ./ex3
// Output: toolchain works
// Exit status (echo $?): 7

    .global _start              // make _start visible to the linker (lesson 04)

    .text                       // what follows is code (lesson 04)
    .p2align 2                  // start on a 4-byte boundary (lesson 04)
_start:                         // the program starts running here (lesson 04)
    mov x0, #1                  // x0 = 1: file descriptor 1 is the screen (lesson 05)
    adrp x1, msg                // x1 = address of msg, part 1 (lesson 05)
    add x1, x1, :lo12:msg       // x1 = address of msg, part 2 (lesson 05)
    mov x2, #len                // x2 = number of bytes to print (lesson 05)
    mov x8, #64                 // 64 is the Linux number for "write" (lesson 05)
    svc #0                      // ask the kernel to do it (lesson 04)

    mov x0, #7                  // x0 = 7: exit status (changed from 0)
    mov x8, #93                 // 93 is the Linux number for "exit" (lesson 04)
    svc #0                      // ask the kernel to end the program (lesson 04)

    .data                       // what follows is data (lesson 05)
msg:
    .ascii "toolchain works\n"  // the bytes to print (lesson 05)
    .equ len, . - msg           // len = how many bytes that was (lesson 05)
