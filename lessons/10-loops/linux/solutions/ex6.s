// ex6.s - Exercise 10.6: clamp a value to 0..100 without branches.
//
// C:      long x = 150;
//         long r = x < 0 ? 0 : x;       // at least 0
//         r = r > 100 ? 100 : r;        // at most 100
//         return r;
// Build:  make
// Run:    ./ex6; echo $?
// Expect: exit status 100. With x = -3: 0. With x = 42: 42.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #150                // x = 150
    mov x2, #100                // the upper limit, in a register for csel
    cmp x1, #0                  // x < 0 ?
    csel x0, xzr, x1, lt        // r = (x < 0) ? 0 : x   (xzr reads as 0)
    cmp x0, x2                  // r > 100 ?
    csel x0, x2, x0, gt         // r = (r > 100) ? 100 : r
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(r)
