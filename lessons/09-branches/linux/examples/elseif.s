// elseif.s - an else-if chain: turn a score into a letter grade.
//
// C:      long s = 85;
//         char g;
//         if (s >= 90)      g = 'A';
//         else if (s >= 80) g = 'B';
//         else if (s >= 70) g = 'C';
//         else              g = 'F';
//         return g;
// Build:  make
// Run:    ./elseif; echo $?
// Expect: exit status 66 ('B')

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #85                 // s = 85

    cmp x1, #90                 // if (s >= 90)
    b.lt try_b                  //   no: try the next test
    mov x0, #'A'                //   g = 'A' (the assembler turns 'A' into 65)
    b done                      //   finished: skip all the other tests
try_b:
    cmp x1, #80                 // else if (s >= 80)
    b.lt try_c                  //   no: next test
    mov x0, #'B'                //   g = 'B'
    b done                      //   finished
try_c:
    cmp x1, #70                 // else if (s >= 70)
    b.lt grade_f                //   no: fall to the final else
    mov x0, #'C'                //   g = 'C'
    b done                      //   finished
grade_f:
    mov x0, #'F'                // else g = 'F'
done:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(g)
