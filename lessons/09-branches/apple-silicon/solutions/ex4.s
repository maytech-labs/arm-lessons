// ex4.s - Exercise 09.4: the sign of a number: -1, 0 or 1 (macOS).
//
// C:      long x = -5, s;
//         if (x < 0)       s = -1;
//         else if (x == 0) s = 0;
//         else             s = 1;
//         return s;
// Build:  make
// Run:    ./ex4; echo $?
// Expect: exit status 255 (-1). With x = 0: 0. With x = 9: 1.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #-5                 // x = -5
    cmp x1, #0                  // compare x with 0 once; both tests reuse the flags
    b.ge not_negative           // NOT (x < 0): try the next test
    mov x0, #-1                 // s = -1
    b done                      // finished
not_negative:
    b.ne positive               // flags still from cmp: NOT (x == 0) -> else
    mov x0, #0                  // s = 0
    b done                      // finished
positive:
    mov x0, #1                  // s = 1
done:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(s)
