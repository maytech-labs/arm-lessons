// countdown.s - count down to zero: subs sets the flags, so no cmp is needed.
//
// C:      long n = 5, f = 1;
//         for (long i = n; i != 0; i--) {     // i = 5, 4, 3, 2, 1
//             f = f * i;
//         }
//         return f;
// Build:  make
// Run:    ./countdown; echo $?
// Expect: exit status 120 (5! = 120)

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #5                  // i = n = 5
    mov x0, #1                  // f = 1
    cbz x1, done                // a for loop tests first: skip it all if i == 0
loop:
    mul x0, x0, x1              // f = f * i
    subs x1, x1, #1             // i = i - 1, AND set the flags from the result
    b.ne loop                   // Z clear means i != 0: go again
done:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(120)
