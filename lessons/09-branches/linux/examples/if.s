// if.s - a single if, translated by inverting the condition.
//
// C:      long x = 15;
//         long r = 0;
//         if (x > 10) {
//             r = 1;
//         }
//         return r;
// Build:  make
// Run:    ./if; echo $?
// Expect: exit status 1. Change x to 5 and it becomes 0.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #15                 // x = 15
    mov x0, #0                  // r = 0
    cmp x1, #10                 // compare x with 10 (sets flags from x - 10)
    b.le end_if                 // NOT (x > 10) is (x <= 10): skip the then-block
    mov x0, #1                  // then-block: r = 1
end_if:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(r)
