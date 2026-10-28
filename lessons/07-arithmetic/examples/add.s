// add.s - add two numbers and return the sum as the exit status.
//
// C:      long a = 20, b = 22;  return a + b;
// Build:  make
// Run:    ./add; echo $?
// Expect: exit status 42

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #20                 // a = 20
    mov x2, #22                 // b = 22
    add x0, x1, x2              // x0 = a + b = 42 (register + register)
    add x0, x0, #0              // x0 = x0 + 0 (register + immediate; no change)
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(42)
