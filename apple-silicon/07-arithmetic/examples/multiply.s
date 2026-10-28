// multiply.s - mul, madd and msub (macOS).
//
// C:      long a = 6, b = 7;
//         long p = a * b;          // 42
//         long s = 100 + a * b;    // 142
//         long t = s - a * b;      // 100
//         return t - p - 16;       // 42
// Build:  make
// Run:    ./multiply; echo $?
// Expect: exit status 42

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #6                  // a = 6
    mov x2, #7                  // b = 7
    mul x3, x1, x2              // p = a * b = 42
    mov x4, #100                // x4 = 100
    madd x5, x1, x2, x4         // s = x4 + a * b = 142   (multiply-add)
    msub x6, x1, x2, x5         // t = s - a * b = 100    (multiply-subtract)
    sub x0, x6, x3              // x0 = t - p = 58
    sub x0, x0, #16             // x0 = 58 - 16 = 42
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(42)
