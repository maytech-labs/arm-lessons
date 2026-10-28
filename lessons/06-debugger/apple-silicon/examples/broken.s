// broken.s - SHOULD print "Hi!" and a newline, but prints nothing. Why?
//
// Build:  make
// Run:    ./broken; echo $?
// Expect: prints NOTHING, exit status 0. Lesson 06 finds the bug with lldb.
//
// (The bug is deliberate. Do not copy this program as a model.)

    .global _main               // make _main visible to the linker

    .data                       // data section
msg:
    .ascii "Hi!\n"              // 4 bytes
    .equ msg_len, . - msg       // msg_len = 4

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    adrp x0, msg@PAGE           // x0 = page of msg
    add x0, x0, msg@PAGEOFF     // x0 = address of msg
    mov x1, #1                  // x1 = 1 (standard output)
    mov x2, #msg_len            // x2 = 4 bytes
    mov x16, #4                 // 4 = write
    svc #0x80                   // write(?, ?, 4)

    mov x0, #0                  // exit status 0
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0)
