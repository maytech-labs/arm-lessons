// hello.s - lesson 05's hello world, used to look at memory in the debugger.
//
// Build:  make
// Run:    ./hello
// Expect: prints "Hello, world!" and a newline, exit status 0

    .global _main               // make _main visible to the linker

    .data                       // data section: our string lives here
msg:
    .ascii "Hello, world!\n"    // 14 bytes, no terminating zero
    .equ msg_len, . - msg       // msg_len = 14

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x0, #1                  // x0 = 1: file descriptor 1 is standard output
    adrp x1, msg@PAGE           // x1 = address of the 4 KiB page holding msg
    add x1, x1, msg@PAGEOFF     // x1 += offset of msg in that page
    mov x2, #msg_len            // x2 = number of bytes to write
    mov x16, #4                 // 4 = write
    svc #0x80                   // write(1, msg, 14); x0 = bytes written

    mov x0, #0                  // exit status 0
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0)
