// ex6.s - Exercise 08.6: round up to the next multiple of 16 (macOS).
//
// C:      unsigned long x = 37;
//         unsigned long r = (x + 15) & ~15ul;   // 48
//         return r;
// Build:  make
// Run:    ./ex6; echo $?
// Expect: exit status 48

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #37                 // x = 37
    add x0, x1, #15             // x + 15 = 52
    and x0, x0, #~15            // clear the low 4 bits: 52 & ~0b1111 = 48
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(48)
