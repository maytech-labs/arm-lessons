// power.s - a for loop: compute base to the power exp (macOS).
//
// C:      long base = 3, exp = 5, result = 1;
//         for (long i = 0; i < exp; i++) {
//             result = result * base;
//         }
//         return result;
// Build:  make
// Run:    ./power; echo $?
// Expect: exit status 243

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #3                  // base = 3
    mov x2, #5                  // exp = 5
    mov x0, #1                  // result = 1
    mov x3, #0                  // init:      i = 0
for_test:
    cmp x3, x2                  // condition: i < exp ?
    b.ge for_end                //   NOT (i < exp) is (i >= exp): leave
    mul x0, x0, x1              // body:      result = result * base
    add x3, x3, #1              // step:      i++
    b for_test                  // back to the condition
for_end:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(243)
