// ex9.s - Exercise 07.9: 100000 * 100000 as int (w) and as long (x).
//
// C:      unsigned int  a = 100000u * 100000u;   // wraps: 1410065408
//         unsigned long b = 100000ul * 100000ul; // 10000000000
// Build:  make
// Run:    ./ex9; echo $?
// Expect: exit status 0 (0x540be400 has low byte 0x00). In gdb at the svc:
//         p/x $x0 = 0x540be400   p/x $x1 = 0x2540be400

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    movz x2, #0x86a0            // 100000 = 0x186a0 does not fit 16 bits:
    movk x2, #0x1, lsl #16      //   build it in two pieces
    mul w0, w2, w2              // 32-bit product: the top bits are lost
    mul x1, x2, x2              // 64-bit product: all of it fits
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(low byte of w0) = exit(0)
