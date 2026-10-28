// ex8.s - Exercise 08.8: isolate the lowest set bit, and count trailing zeros.
//
// C:      unsigned long x = 88;        // 0b101_1000
//         unsigned long low = x & -x;  // 0b000_1000 = 8
//         int tz = __builtin_ctzl(x);  // 3
//         return tz;
// Build:  make
// Run:    ./ex8; echo $?
// Expect: exit status 3. In gdb, x1 = 8.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x2, #88                 // x = 0b101_1000
    neg x3, x2                  // -x = ~x + 1: flips every bit above the lowest 1
    and x1, x2, x3              // x & -x = 0b1000 = 8
    rbit x0, x2                 // reverse the bits: trailing zeros become leading
    clz x0, x0                  // count them: 3
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(3)
