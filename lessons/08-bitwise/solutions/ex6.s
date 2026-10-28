// ex6.s - Exercise 08.6: round up to the next multiple of 16.
//
// C:      unsigned long x = 37;
//         unsigned long r = (x + 15) & ~15ul;   // 48
//         return r;
// Build:  make
// Run:    ./ex6; echo $?
// Expect: exit status 48

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #37                 // x = 37
    add x0, x1, #15             // x + 15 = 52
    and x0, x0, #~15            // clear the low 4 bits: 52 & ~0b1111 = 48
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(48)
