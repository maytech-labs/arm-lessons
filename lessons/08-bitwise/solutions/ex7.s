// ex7.s - Exercise 08.7: reverse the bytes of a 32-bit value.
//
// C:      unsigned x = 0x11223344;
//         unsigned y = __builtin_bswap32(x);   // 0x44332211
//         return y & 0xff;                     // 0x11
// Build:  make
// Run:    ./ex7; echo $?
// Expect: exit status 17 (0x11, now the lowest byte). In gdb, x0 = 0x44332211.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    movz w1, #0x3344            // w1 = 0x00003344
    movk w1, #0x1122, lsl #16   // w1 = 0x11223344
    rev w0, w1                  // reverse the 4 bytes of the w register: 0x44332211
    mov x8, #93                 // 93 = exit
    svc #0                      // exit: low byte is 0x11 = 17
