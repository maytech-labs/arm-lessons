// broken.s - SHOULD print "Hi!" and a newline, but prints nothing. Why?
//
// Build:  make
// Run:    ./broken; echo $?
// Expect: prints NOTHING, exit status 0. Lesson 06 finds the bug with gdb.
//
// (The bug is deliberate. Do not copy this program as a model.)

    .global _start              // make _start visible to the linker

    .data                       // data section
msg:
    .ascii "Hi!\n"              // 4 bytes
    .equ msg_len, . - msg       // msg_len = 4

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    adrp x0, msg                // x0 = page of msg
    add x0, x0, :lo12:msg       // x0 = address of msg
    mov x1, #1                  // x1 = 1 (standard output)
    mov x2, #msg_len            // x2 = 4 bytes
    mov x8, #64                 // 64 = write
    svc #0                      // write(?, ?, 4)

    mov x0, #0                  // exit status 0
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(0)
