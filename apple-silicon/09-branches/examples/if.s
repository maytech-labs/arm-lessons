// if.s - a single if, translated by inverting the condition (macOS).
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

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #15                 // x = 15
    mov x0, #0                  // r = 0
    cmp x1, #10                 // compare x with 10 (sets flags from x - 10)
    b.le end_if                 // NOT (x > 10) is (x <= 10): skip the then-block
    mov x0, #1                  // then-block: r = 1
end_if:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(r)
