// branchless.s - csel, cset, csinc, cinc, cneg: decisions without branches (macOS).
//
// C:      long a = 17, b = 42;
//         long mn = a < b ? a : b;           // 17
//         long mx = a > b ? a : b;           // 42
//         long eq = a == b;                  // 0
//         long d  = a - b;                   // -25
//         long ad = d < 0 ? -d : d;          // 25  (abs)
//         long n  = 5 + (a < b);             // 6
//         return ad;
// Build:  make
// Run:    ./branchless; echo $?
// Expect: exit status 25. In lldb: x3 = 17, x4 = 42, x5 = 0, x6 = 6, x7 = 18.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #17                 // a = 17
    mov x2, #42                 // b = 42

    cmp x1, x2                  // one compare; every instruction below reads it
    csel x3, x1, x2, lt         // mn = (a < b) ? a : b     = 17
    csel x4, x1, x2, gt         // mx = (a > b) ? a : b     = 42
    cset x5, eq                 // eq = (a == b) ? 1 : 0    = 0
    mov x6, #5                  // n = 5
    cinc x6, x6, lt             // n = (a < b) ? n + 1 : n  = 6
    csinc x7, x2, x1, ge        // x7 = (a >= b) ? b : a + 1 = 18

    sub x0, x1, x2              // d = a - b = -25
    cmp x0, #0                  // compare d with 0
    cneg x0, x0, lt             // ad = (d < 0) ? -d : d = 25
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(25)
