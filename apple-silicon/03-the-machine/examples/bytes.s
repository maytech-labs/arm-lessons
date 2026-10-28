// bytes.s - puts some known bytes in memory so you can look at them (macOS). Exits with status 0.
//
// The .data part uses directives (.byte, .word, .ascii) that are explained
// properly in lessons 05 and 11. Here they just say "put these bytes here".
//
// Build:  make
// Run:    ./bytes
// Look:   objdump -s -j __data bytes     (the data bytes)
//         objdump -s -j __text bytes     (the instruction bytes)
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2
_main:
    mov x0, #0                  // exit status 0
    mov x16, #1                 // macOS system call number for exit
    svc #0x80                   // exit

    .data                       // what follows is data, not code
    .byte 0x01, 0x02, 0x03, 0x04    // four single bytes, in this order
    .word 0x12345678            // one 32-bit word (4 bytes): watch the byte order
    .ascii "Hi!"                // three bytes: the character codes of H, i, !
