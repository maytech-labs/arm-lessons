// ex3.s - Exercise 10.3: the 13th Fibonacci number.
//
// C:      long a = 0, b = 1;            // fib(0), fib(1)
//         for (long i = 0; i < 13; i++) {
//             long t = a + b;
//             a = b;
//             b = t;
//         }
//         return a;                     // fib(13)
// Build:  make
// Run:    ./ex3; echo $?
// Expect: exit status 233

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #0                  // a = fib(0)
    mov x1, #1                  // b = fib(1)
    mov x2, #13                 // count down 13 times
loop:                           // invariant: a = fib(k), b = fib(k + 1)
    add x3, x0, x1              // t = a + b
    mov x0, x1                  // a = b
    mov x1, x3                  // b = t
    subs x2, x2, #1             // one fewer to go; sets Z when it reaches 0
    b.ne loop                   // repeat until the count is 0
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(233)
