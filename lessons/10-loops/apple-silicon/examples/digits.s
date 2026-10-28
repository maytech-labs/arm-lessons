// digits.s - a do-while loop: count the decimal digits of a number (macOS).
//
// C:      unsigned long n = 12345, count = 0;
//         do {
//             count = count + 1;
//             n = n / 10;
//         } while (n != 0);
//         return count;
// Build:  make
// Run:    ./digits; echo $?
// Expect: exit status 5 (and 1 for n = 0: the body always runs once)

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #12345              // n = 12345
    mov x2, #10                 // divisor 10
    mov x0, #0                  // count = 0
loop:
    add x0, x0, #1              // body: count = count + 1
    udiv x1, x1, x2             //       n = n / 10
    cbnz x1, loop               // while (n != 0): test at the BOTTOM, jump back
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(count)
