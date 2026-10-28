// collatz.s - how many Collatz steps does it take to reach 1? (macOS)
//
// C:      unsigned long n = 27, steps = 0;
//         while (n != 1) {
//             if (n % 2 == 0) n = n / 2;
//             else            n = 3 * n + 1;
//             steps++;
//         }
//         return steps;
// Build:  make
// Run:    ./collatz; echo $?
// Expect: exit status 111

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #27                 // n = 27
    mov x0, #0                  // steps = 0
loop:
    cmp x1, #1                  // while (n != 1)
    b.eq done                   //   n == 1: leave
    tbnz x1, #0, odd            // bit 0 set means n is odd
    lsr x1, x1, #1              // even: n = n / 2 (a shift, lesson 08)
    b next                      // skip the odd case
odd:
    add x1, x1, x1, lsl #1      // odd: n = n + 2n = 3n
    add x1, x1, #1              //      n = 3n + 1
next:
    add x0, x0, #1              // steps++
    b loop                      // test again
done:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(111)
