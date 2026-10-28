// ex3.s - Exercise 08.3: set bit 0, clear bit 7, toggle bit 4 of 178.
//
// C:      unsigned long v = 178;     // 0b1011_0010
//         v |= 1 << 0;               // 0b1011_0011 = 179
//         v &= ~(1 << 7);            // 0b0011_0011 = 51
//         v ^= 1 << 4;               // 0b0010_0011 = 35
//         return v;
// Build:  make
// Run:    ./ex3; echo $?
// Expect: exit status 35

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #178                // v = 0b1011_0010
    orr x0, x0, #(1 << 0)       // set bit 0:    179
    bic x0, x0, #(1 << 7)       // clear bit 7:  51  (bic with an immediate is
                                //   accepted: it means and x0, x0, #~(1 << 7))
    eor x0, x0, #(1 << 4)       // toggle bit 4: 35
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(35)
