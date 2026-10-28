// ex6.s - Exercise 09.6: classify a character.
//
// C:      long c = 'q', k;
//         if (c >= '0' && c <= '9')      k = 1;   // digit
//         else if (c >= 'a' && c <= 'z') k = 2;   // lowercase
//         else if (c >= 'A' && c <= 'Z') k = 3;   // uppercase
//         else                           k = 0;   // anything else
//         return k;
// Build:  make
// Run:    ./ex6; echo $?
// Expect: exit status 2. Try '7' (1), 'Q' (3), '#' (0).

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #'q'                // c = 'q'

    cmp x1, #'0'                // c >= '0' ?
    b.lt try_lower              //   no
    cmp x1, #'9'                // c <= '9' ?
    b.gt try_lower              //   no
    mov x0, #1                  // digit
    b done                      // finished
try_lower:
    cmp x1, #'a'                // c >= 'a' ?
    b.lt try_upper              //   no
    cmp x1, #'z'                // c <= 'z' ?
    b.gt try_upper              //   no
    mov x0, #2                  // lowercase
    b done                      // finished
try_upper:
    cmp x1, #'A'                // c >= 'A' ?
    b.lt other                  //   no
    cmp x1, #'Z'                // c <= 'Z' ?
    b.gt other                  //   no
    mov x0, #3                  // uppercase
    b done                      // finished
other:
    mov x0, #0                  // anything else
done:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(k)
