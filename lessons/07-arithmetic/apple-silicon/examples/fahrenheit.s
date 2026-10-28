// fahrenheit.s - convert 100 degrees Celsius to Fahrenheit (macOS).
//
// C:      long c = 100;  long f = c * 9 / 5 + 32;  return f;
// Build:  make
// Run:    ./fahrenheit; echo $?
// Expect: exit status 212

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #100                // c = 100
    mov x2, #9                  // mul has no immediate form: put 9 in a register
    mul x0, x1, x2              // x0 = c * 9 = 900
    mov x2, #5                  // divisor 5, also in a register
    sdiv x0, x0, x2             // x0 = 900 / 5 = 180
    add x0, x0, #32             // x0 = 180 + 32 = 212
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(212)
