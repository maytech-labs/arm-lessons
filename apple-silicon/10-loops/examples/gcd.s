// gcd.s - Euclid's greatest common divisor (macOS).
//
// C:      unsigned long a = 1071, b = 462;
//         while (b != 0) {
//             unsigned long t = a % b;
//             a = b;
//             b = t;
//         }
//         return a;
// Build:  make
// Run:    ./gcd; echo $?
// Expect: exit status 21

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x0, #1071               // a = 1071
    mov x1, #462                // b = 462
loop:                           // invariant: gcd(a, b) never changes
    cbz x1, done                // while (b != 0): leave when b == 0
    udiv x2, x0, x1             // q = a / b
    msub x2, x2, x1, x0         // t = a - q * b = a % b
    mov x0, x1                  // a = b
    mov x1, x2                  // b = t
    b loop                      // test again
done:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(a) = exit(21)
