// shiftmul.s - multiply by constants using shifted register operands.
//
// C:      long x = 7;
//         long t = x * 10;     // = (x << 3) + (x << 1)
//         long s = x * 7;      // = (x << 3) - x
//         return t;
// Build:  make
// Run:    ./shiftmul; echo $?
// Expect: exit status 70. In gdb, x3 = 49.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #7                  // x = 7
    add x2, x1, x1, lsl #2      // x2 = x + (x << 2) = x * 5 = 35
    lsl x0, x2, #1              // x0 = x2 << 1 = x * 10 = 70
    lsl x3, x1, #3              // x3 = x << 3 = x * 8 = 56
    sub x3, x3, x1              // x3 = x * 8 - x = x * 7 = 49
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(70)
