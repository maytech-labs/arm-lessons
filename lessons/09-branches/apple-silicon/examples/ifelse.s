// ifelse.s - if/else: the larger of two numbers (macOS).
//
// C:      long a = 17, b = 42, m;
//         if (a >= b) {
//             m = a;
//         } else {
//             m = b;
//         }
//         return m;
// Build:  make
// Run:    ./ifelse; echo $?
// Expect: exit status 42

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #17                 // a = 17
    mov x2, #42                 // b = 42
    cmp x1, x2                  // compare a with b
    b.lt else                   // NOT (a >= b) is (a < b): go to the else-block
    mov x0, x1                  // then-block: m = a
    b end_if                    // skip over the else-block
else:
    mov x0, x2                  // else-block: m = b
end_if:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(m)
