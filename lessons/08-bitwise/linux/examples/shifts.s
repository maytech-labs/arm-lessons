// shifts.s - lsl, lsr, asr and ror on a negative number.
//
// C:      long          s = -16;
//         unsigned long u = (unsigned long)s;
//         long a = s << 2;          // -64
//         unsigned long b = u >> 2; // 0x3ffffffffffffffc (logical: zeros come in)
//         long c = s >> 2;          // -4  (arithmetic: copies of the sign bit come in)
//         return c;
// Build:  make
// Run:    ./shifts; echo $?
// Expect: exit status 252 (-4 as a byte). Look at x1, x2, x4 in gdb.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #-16                // s = -16 = 0xfffffffffffffff0
    lsl x1, x0, #2              // a = s << 2 = -64 (0xffffffffffffffc0)
    lsr x2, x0, #2              // b = u >> 2 = 0x3ffffffffffffffc
    asr x3, x0, #2              // c = s >> 2 = -4  (0xfffffffffffffffc)
    mov x5, #1                  // x5 = 1
    ror x4, x5, #1              // rotate right 1: bit 0 comes back in at bit 63
                                //   x4 = 0x8000000000000000
    mov x0, x3                  // return c
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(-4): the shell sees 252
