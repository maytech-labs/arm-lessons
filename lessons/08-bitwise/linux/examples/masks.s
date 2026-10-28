// masks.s - set, clear, toggle and test single bits with masks.
//
// C:      unsigned long v = 5;                // 0b0000_0101
//         v = v | (1 << 3);                   // set bit 3:    0b0000_1101 = 13
//         v = v & ~(1 << 0);                  // clear bit 0:  0b0000_1100 = 12
//         v = v ^ (1 << 7);                   // toggle bit 7: 0b1000_1100 = 140
//         unsigned long t = v & (1 << 2);     // test bit 2:   4 (nonzero: set)
//         return v;
// Build:  make
// Run:    ./masks; echo $?
// Expect: exit status 140. In gdb, x1 = 4.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #5                  // v = 0b0000_0101
    orr x0, x0, #(1 << 3)       // set bit 3:    v = 13
    and x0, x0, #~(1 << 0)      // clear bit 0:  v = 12 (mask is all ones but bit 0)
    eor x0, x0, #(1 << 7)       // toggle bit 7: v = 140
    and x1, x0, #(1 << 2)       // test bit 2:   x1 = 4, so bit 2 is set
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(140)
