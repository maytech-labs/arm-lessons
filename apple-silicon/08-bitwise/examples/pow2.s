// pow2.s - x & (x - 1) clears the lowest set bit; it is 0 only for powers of 2 (macOS).
//
// C:      unsigned long a = 64, b = 96;
//         unsigned long ta = a & (a - 1);   // 0:  64 is a power of two
//         unsigned long tb = b & (b - 1);   // 64: 96 = 0b110_0000 is not
//         return tb;
// Build:  make
// Run:    ./pow2; echo $?
// Expect: exit status 64. In lldb, x3 = 0.
//
// Lesson 09 turns "is it zero?" into a decision with a branch.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #64                 // a = 0b100_0000
    sub x2, x1, #1              // a - 1 = 0b011_1111
    and x3, x1, x2              // 0b100_0000 & 0b011_1111 = 0
    mov x4, #96                 // b = 0b110_0000
    sub x5, x4, #1              // b - 1 = 0b101_1111
    and x0, x4, x5              // 0b110_0000 & 0b101_1111 = 0b100_0000 = 64
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(64)
