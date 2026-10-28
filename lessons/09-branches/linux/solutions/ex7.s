// ex7.s - Exercise 09.7: the fixed version of the size check.
//
// C:      unsigned long size  = 0x8000000000000000;   // huge
//         unsigned long limit = 100;
//         long too_big = 0;
//         if (size > limit) too_big = 1;
//         return too_big;
// Build:  make
// Run:    ./ex7; echo $?
// Expect: exit status 1. (The buggy version with b.le exits 0.)

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    movz x1, #0x8000, lsl #48   // size = 0x8000000000000000
    mov x2, #100                // limit = 100
    mov x0, #0                  // too_big = 0
    cmp x1, x2                  // compare size with limit
    b.ls end_if                 // UNSIGNED: NOT (size > limit) is (size <= limit) = ls
                                //   (the bug was b.le, which reads size as negative)
    mov x0, #1                  // too_big = 1
end_if:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(too_big)
