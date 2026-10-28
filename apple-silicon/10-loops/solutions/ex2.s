// ex2.s - Exercise 10.2: the sum of the even numbers 2 + 4 + ... + 20 (macOS).
//
// C:      long sum = 0;
//         for (long i = 2; i <= 20; i += 2) sum += i;
//         return sum;
// Build:  make
// Run:    ./ex2; echo $?
// Expect: exit status 110

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x0, #0                  // sum = 0
    mov x1, #2                  // i = 2
loop:
    cmp x1, #20                 // i <= 20 ?
    b.gt done                   //   no: leave
    add x0, x0, x1              // sum += i
    add x1, x1, #2              // i += 2
    b loop                      // again
done:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(110)
