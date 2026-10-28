// ex5.s - Exercise 08.5: unpack a 16-bit FAT-style date.
//
// Layout: bits 15-9 year - 1980 (7 bits), bits 8-5 month (4 bits),
//         bits 4-0 day (5 bits).  0x5d5b is 2026-10-27.
// C:      unsigned d = 0x5d5b;
//         unsigned day   = d & 0x1f;              // 27
//         unsigned month = (d >> 5) & 0xf;        // 10
//         unsigned year  = (d >> 9) + 1980;       // 2026
//         return month;
// Build:  make
// Run:    ./ex5; echo $?
// Expect: exit status 10. In gdb, x1 = 27 and x2 = 2026.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x3, #0x5d5b             // d = the packed date
    ubfx x1, x3, #0, #5         // day   = bits 0-4  = 27 (same as and x1, x3, #0x1f)
    ubfx x0, x3, #5, #4         // month = bits 5-8  = 10
    ubfx x2, x3, #9, #7         // year offset = bits 9-15 = 46
    add x2, x2, #1980           // year = 46 + 1980 = 2026
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(10)
