// add.s - add two numbers and return the sum as the exit status (macOS).
//
// C:      long a = 20, b = 22;  return a + b;
// Build:  make
// Run:    ./add; echo $?
// Expect: exit status 42

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #20                 // a = 20
    mov x2, #22                 // b = 22
    add x0, x1, x2              // x0 = a + b = 42 (register + register)
    add x0, x0, #0              // x0 = x0 + 0 (register + immediate; no change)
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(42)
