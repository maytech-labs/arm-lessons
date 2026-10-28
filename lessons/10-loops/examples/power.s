// power.s - a for loop: compute base to the power exp.
//
// C:      long base = 3, exp = 5, result = 1;
//         for (long i = 0; i < exp; i++) {
//             result = result * base;
//         }
//         return result;
// Build:  make
// Run:    ./power; echo $?
// Expect: exit status 243

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
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
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(243)
