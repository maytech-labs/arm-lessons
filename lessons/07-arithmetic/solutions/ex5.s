// ex5.s - Exercise 07.5: split 7384 seconds into hours, minutes, seconds.
//
// C:      long t = 7384;
//         long h = t / 3600;          // 2
//         long m = t % 3600 / 60;     // 3
//         long s = t % 60;            // 4
//         return h * 100 + m * 10 + s;
// Build:  make
// Run:    ./ex5; echo $?
// Expect: exit status 234

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #7384               // t = 7384 (fits a 16-bit mov immediate)
    mov x2, #3600               // seconds per hour
    udiv x3, x1, x2             // h = t / 3600 = 2
    msub x4, x3, x2, x1         // rest = t - h * 3600 = 184
    mov x2, #60                 // seconds per minute
    udiv x5, x4, x2             // m = 184 / 60 = 3
    msub x6, x5, x2, x4         // s = 184 - 3 * 60 = 4

    mov x2, #100                // build h * 100 + m * 10 + s
    mul x0, x3, x2              // x0 = h * 100 = 200
    mov x2, #10                 // multiplier 10
    madd x0, x5, x2, x0         // x0 = x0 + m * 10 = 230
    add x0, x0, x6              // x0 = 230 + s = 234
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(234)
