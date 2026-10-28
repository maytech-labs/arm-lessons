// skip.s - continue and break inside a loop (macOS).
//
// C:      long sum = 0;
//         for (long i = 1; ; i++) {
//             if (i > 20) break;          // leave the loop completely
//             if (i % 3 == 0) continue;   // skip the rest of this iteration
//             sum += i;
//         }
//         return sum;                     // 1+2+4+5+7+8+...+19+20
// Build:  make
// Run:    ./skip; echo $?
// Expect: exit status 147

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x0, #0                  // sum = 0
    mov x1, #1                  // i = 1
    mov x3, #3                  // divisor 3
loop:
    cmp x1, #20                 // if (i > 20)
    b.gt end_loop               //   break: jump PAST the loop
    udiv x2, x1, x3             // i / 3
    msub x2, x2, x3, x1         // x2 = i % 3
    cbz x2, continue            // if (i % 3 == 0) continue: jump to the step
    add x0, x0, x1              // sum += i
continue:
    add x1, x1, #1              // step: i++  (continue lands here, not at loop)
    b loop                      // next iteration
end_loop:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(147)
