// bitfields.s - pack and unpack an RGB565 colour with bfi and ubfx.
//
// RGB565 squeezes a colour into 16 bits:
//     bits 15-11: red (5 bits)   bits 10-5: green (6 bits)   bits 4-0: blue (5 bits)
//
// C:      unsigned r = 31, g = 40, b = 12;
//         unsigned c = (r << 11) | (g << 5) | b;   // 0xfd0c
//         unsigned green = (c >> 5) & 0x3f;        // 40
//         return green;
// Build:  make
// Run:    ./bitfields; echo $?
// Expect: exit status 40. In gdb, x4 = 0xfd0c and x6 = -1.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #31                 // red   = 31 (0b11111)
    mov x2, #40                 // green = 40 (0b101000)
    mov x3, #12                 // blue  = 12 (0b01100)

    mov x4, x3                  // c = blue, in bits 4-0
    bfi x4, x2, #5, #6          // insert the low 6 bits of green at bit 5
    bfi x4, x1, #11, #5         // insert the low 5 bits of red at bit 11
                                //   c = 0xfd0c
    ubfx x0, x4, #5, #6         // extract 6 bits starting at bit 5: green = 40
    ubfx x5, x4, #11, #5        // red again: 31 (unsigned field: 0b11111)
    sbfx x6, x4, #11, #5        // the same 5 bits read as SIGNED: 0b11111 = -1
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(40)
