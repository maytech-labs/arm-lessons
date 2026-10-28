// sum.s - a while loop: add up 1 + 2 + ... + n (macOS).
//
// C:      long n = 10, i = 1, sum = 0;
//         while (i <= n) {
//             sum = sum + i;
//             i = i + 1;
//         }
//         return sum;
// Build:  make
// Run:    ./sum; echo $?
// Expect: exit status 55

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #10                 // n = 10
    mov x2, #1                  // i = 1
    mov x0, #0                  // sum = 0
loop:                           // invariant here: sum = 1 + 2 + ... + (i - 1)
    cmp x2, x1                  // test the condition: i <= n ?
    b.gt end_loop               // NOT (i <= n) is (i > n): leave the loop
    add x0, x0, x2              // body: sum = sum + i
    add x2, x2, #1              // i = i + 1
    b loop                      // back to the test
end_loop:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(sum)
