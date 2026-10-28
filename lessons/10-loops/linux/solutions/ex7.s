// ex7.s - Exercise 10.7: integer square root by counting up.
//
// C:      unsigned long n = 200, r = 0;
//         while ((r + 1) * (r + 1) <= n) r++;
//         return r;                      // largest r with r * r <= n
// Build:  make
// Run:    ./ex7; echo $?
// Expect: exit status 14 (14 * 14 = 196, 15 * 15 = 225)

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #200                // n = 200
    mov x0, #0                  // r = 0
loop:                           // invariant: r * r <= n
    add x2, x0, #1              // r + 1
    mul x3, x2, x2              // (r + 1) * (r + 1)
    cmp x3, x1                  // <= n ?
    b.hi done                   //   no (unsigned >): r is the answer
    mov x0, x2                  // r++
    b loop                      // again
done:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(14)
