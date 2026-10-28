// bigconst.s - build a 64-bit constant 16 bits at a time with movz and movk.
//
// C:      unsigned long x = 0x1122334455667788;  return x & 0xff;
// Build:  make
// Run:    ./bigconst; echo $?
// Expect: exit status 136 (0x88, the lowest byte). Look at all of x0 in gdb.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    movz x0, #0x7788            // x0 = 0x0000000000007788 (other bits zeroed)
    movk x0, #0x5566, lsl #16   // x0 = 0x0000000055667788 (bits 16-31 replaced)
    movk x0, #0x3344, lsl #32   // x0 = 0x0000334455667788 (bits 32-47 replaced)
    movk x0, #0x1122, lsl #48   // x0 = 0x1122334455667788 (bits 48-63 replaced)
    mov x8, #93                 // 93 = exit
    svc #0                      // exit: the shell keeps only the low byte, 0x88
