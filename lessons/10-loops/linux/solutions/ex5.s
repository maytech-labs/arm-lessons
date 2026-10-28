// ex5.s - Exercise 10.5: count the 1 bits in a number (population count).
//
// C:      unsigned long x = 0xf0f0, count = 0;
//         while (x != 0) {
//             count += x & 1;
//             x >>= 1;
//         }
//         return count;
// Build:  make
// Run:    ./ex5; echo $?
// Expect: exit status 8

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #0xf0f0             // x = 0xf0f0
    mov x0, #0                  // count = 0
loop:
    cbz x1, done                // while (x != 0)
    and x2, x1, #1              // the lowest bit: 0 or 1
    add x0, x0, x2              // count += x & 1
    lsr x1, x1, #1              // x >>= 1 (unsigned: logical shift)
    b loop                      // again
done:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(8)
