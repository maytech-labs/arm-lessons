// ex8.s - Exercise 10.8: count the primes below 100 (nested loops, break).
//
// C:      long count = 0;
//         for (long n = 2; n < 100; n++) {
//             long prime = 1;
//             for (long d = 2; d * d <= n; d++) {
//                 if (n % d == 0) { prime = 0; break; }
//             }
//             count += prime;
//         }
//         return count;
// Build:  make
// Run:    ./ex8; echo $?
// Expect: exit status 25

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #0                  // count = 0
    mov x1, #2                  // n = 2
outer:
    cmp x1, #100                // n < 100 ?
    b.ge outer_end              //   no: finished
    mov x3, #1                  // prime = 1 (assume prime until proven otherwise)
    mov x2, #2                  // d = 2
inner:
    mul x4, x2, x2              // d * d
    cmp x4, x1                  // d * d <= n ?
    b.gt inner_end              //   no: no divisor found
    udiv x5, x1, x2             // n / d
    msub x5, x5, x2, x1         // x5 = n % d
    cbnz x5, inner_next         // not a divisor: try the next d
    mov x3, #0                  // a divisor: prime = 0
    b inner_end                 // break out of the INNER loop only
inner_next:
    add x2, x2, #1              // d++
    b inner                     // next divisor
inner_end:
    add x0, x0, x3              // count += prime
    add x1, x1, #1              // n++
    b outer                     // next number
outer_end:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(25)
