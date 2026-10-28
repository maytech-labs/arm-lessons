// ex6.s - Exercise 07.6: evaluate 3x^2 + 2x + 1 at x = 5 with madd.
//
// Horner's form: 3x^2 + 2x + 1 = (3x + 2) * x + 1
// Build:  make
// Run:    ./ex6; echo $?
// Expect: exit status 86

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #5                  // x = 5
    mov x2, #3                  // coefficient 3
    mov x3, #2                  // coefficient 2
    mov x4, #1                  // coefficient 1
    madd x0, x2, x1, x3         // x0 = 2 + 3 * x = 17
    madd x0, x0, x1, x4         // x0 = 1 + 17 * x = 86
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(86)
