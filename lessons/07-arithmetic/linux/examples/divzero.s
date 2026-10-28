// divzero.s - dividing by zero does not crash on AArch64: the result is 0.
//
// C:      long a = 42, b = 0;  return a / b;   // undefined behaviour in C!
// Build:  make
// Run:    ./divzero; echo $?
// Expect: exit status 0

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #42                 // a = 42
    mov x2, #0                  // b = 0
    udiv x0, x1, x2             // x0 = 42 / 0 = 0 on AArch64 (no trap, no signal)
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(0)
