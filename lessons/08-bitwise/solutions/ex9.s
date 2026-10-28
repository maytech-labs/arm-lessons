// ex9.s - Exercise 08.9: absolute value without any branch.
//
// C:      long x = -42;
//         long m = x >> 63;        // all ones if x < 0, else 0
//         long a = (x ^ m) - m;    // ~x + 1 = -x when negative, x otherwise
//         return a;
// Build:  make
// Run:    ./ex9; echo $?
// Expect: exit status 42

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #-42                // x = -42
    asr x2, x1, #63             // m = 0xffffffffffffffff (x is negative)
    eor x0, x1, x2              // x ^ m = ~x = 41
    sub x0, x0, x2              // 41 - (-1) = 42
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(42)
