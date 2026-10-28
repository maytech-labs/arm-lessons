// bytes.s - some data to examine with the debugger's x command.
//
// Build:  make
// Run:    ./bytes; echo $?
// Expect: exit status 0 (nothing is printed; the point is to look at memory)
//
// .byte puts single bytes in memory; .quad puts one 8-byte (64-bit) number.

    .global _main               // make _main visible to the linker

    .data                       // data section
word:
    .ascii "ARM!"               // 4 bytes: 0x41 0x52 0x4d 0x21
small:
    .byte 1, 2, 3, 0xff         // 4 single bytes
big:
    .quad 0x1122334455667788    // one 64-bit number (8 bytes)
    .quad 42                    // another one

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    adrp x1, big@PAGE           // x1 = page of big
    add x1, x1, big@PAGEOFF     // x1 = address of big
    mov x0, #0                  // exit status 0
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0)
