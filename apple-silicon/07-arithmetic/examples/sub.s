// sub.s - subtraction that goes below zero, and neg (macOS).
//
// C:      long a = 10, b = 13;  long d = a - b;  return -(-d);
// Build:  make
// Run:    ./sub; echo $?
// Expect: exit status 253, which is -3 seen as an unsigned byte

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #10                 // a = 10
    mov x2, #13                 // b = 13
    sub x3, x1, x2              // d = a - b = -3 = 0xfffffffffffffffd
    neg x4, x3                  // x4 = -d = 3
    neg x0, x4                  // x0 = -3 again
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(-3): the shell sees -3 & 0xff = 253
