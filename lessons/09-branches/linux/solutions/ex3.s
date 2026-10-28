// ex3.s - Exercise 09.3: absolute value with a branch.
//
// C:      long x = -42;
//         if (x < 0) {
//             x = -x;
//         }
//         return x;
// Build:  make
// Run:    ./ex3; echo $?
// Expect: exit status 42 (also 42 if you start with x = 42)

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #-42                // x = -42
    cmp x0, #0                  // compare x with 0
    b.ge end_if                 // NOT (x < 0) is (x >= 0): skip
    neg x0, x0                  // x = -x
end_if:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(x)
