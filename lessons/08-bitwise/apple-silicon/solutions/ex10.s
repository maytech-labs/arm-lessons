// ex10.s - Exercise 08.10: pack day 27, month 10, year 2026 into a 16-bit date (macOS).
//
// Same layout as exercise 08.5: year-1980 in bits 15-9, month in 8-5, day in 4-0.
// C:      unsigned d = ((2026 - 1980) << 9) | (10 << 5) | 27;   // 0x5d5b
//         return d & 0xff;
// Build:  make
// Run:    ./ex10; echo $?
// Expect: exit status 91 (0x5b). In lldb, x0 = 0x5d5b.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #27                 // day
    mov x2, #10                 // month
    mov x3, #2026               // year
    sub x3, x3, #1980           // year offset = 46
    mov x0, x1                  // d = day (bits 4-0)
    bfi x0, x2, #5, #4          // put month into bits 8-5
    bfi x0, x3, #9, #7          // put year offset into bits 15-9
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0x5b) = exit(91)
