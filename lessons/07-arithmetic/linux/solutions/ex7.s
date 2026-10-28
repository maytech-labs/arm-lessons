// ex7.s - Exercise 07.7: C's / and % on a negative number.
//
// C:      long a = -17, b = 5;
//         long q = a / b;     // -3
//         long r = a % b;     // -2
//         return r;
// Build:  make
// Run:    ./ex7; echo $?
// Expect: exit status 254 (-2 as a byte). In gdb, p $x3 shows -3.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #-17                // a = -17
    mov x2, #5                  // b = 5
    sdiv x3, x1, x2             // q = -17 / 5 = -3 (truncates toward zero)
    msub x0, x3, x2, x1         // r = a - q * b = -17 - (-15) = -2
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(-2): the shell sees 254
