// bitcount.s - clz (count leading zeros), rbit (reverse bits), rev (reverse bytes).
//
// C (gcc builtins):
//         unsigned long x = 0xf0;
//         int lead  = __builtin_clzl(x);   // 56 zero bits above the top 1
//         int trail = __builtin_ctzl(x);   // 4  zero bits below the lowest 1
// Build:  make
// Run:    ./bitcount; echo $?
// Expect: exit status 56. In gdb, x2 = 4 and x4 = 0x8877665544332211.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #0xf0               // x = 0b1111_0000
    clz x0, x1                  // leading zeros: 64 - 8 = 56
    rbit x2, x1                 // reverse all 64 bits: 0x0f00000000000000
    clz x2, x2                  // leading zeros of the reversed value
                                //   = trailing zeros of x = 4
    movz x3, #0x7788            // x3 = 0x1122334455667788 (lesson 07)
    movk x3, #0x5566, lsl #16   // bits 16-31
    movk x3, #0x3344, lsl #32   // bits 32-47
    movk x3, #0x1122, lsl #48   // bits 48-63
    rev x4, x3                  // reverse the 8 bytes: 0x8877665544332211
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(56)
