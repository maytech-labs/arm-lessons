// cbz.s - compare-and-branch: cbz/cbnz test for zero, tbz/tbnz test one bit (macOS).
//
// C:      long n = 7;
//         long r = 0;
//         if (n != 0) r += 10;
//         if (n & 1)  r += 1;      // odd?
//         return r;
// Build:  make
// Run:    ./cbz; echo $?
// Expect: exit status 11. With n = 0 it is 0; with n = 4 it is 10.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #7                  // n = 7
    mov x0, #0                  // r = 0

    cbz x1, skip_nonzero        // NOT (n != 0) is (n == 0): skip. No cmp needed!
    add x0, x0, #10             // r += 10
skip_nonzero:
    tbz x1, #0, skip_odd        // bit 0 of n is 0 (n is even): skip
    add x0, x0, #1              // r += 1
skip_odd:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(r)
