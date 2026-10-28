// ex4.s - Exercise 08.4: x * 9 and x * 15 without mul.
//
// C:      long x = 13;
//         long a = x * 9;      // x + (x << 3)  = 117
//         long b = x * 15;     // (x << 4) - x  = 195
//         return b;
// Build:  make
// Run:    ./ex4; echo $?
// Expect: exit status 195. In gdb, x1 = 117.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x2, #13                 // x = 13
    add x1, x2, x2, lsl #3      // a = x + (x << 3) = x * 9 = 117
    lsl x0, x2, #4              // x0 = x << 4 = x * 16 = 208
    sub x0, x0, x2              // b = x * 16 - x = x * 15 = 195
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(195)
