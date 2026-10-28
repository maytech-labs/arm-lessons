// ex2.s - Exercise 07.2: compute (7 + 8) * 3 - 4.
//
// Build:  make
// Run:    ./ex2; echo $?
// Expect: exit status 41

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #7                  // x1 = 7
    add x1, x1, #8              // x1 = 7 + 8 = 15
    mov x2, #3                  // mul needs both operands in registers
    mul x0, x1, x2              // x0 = 15 * 3 = 45
    sub x0, x0, #4              // x0 = 45 - 4 = 41
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(41)
