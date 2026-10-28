// many_args.s - more than eight arguments: the rest go on the stack (macOS).
//
// C:      long sum10(long a, long b, long c, long d, long e,
//                    long f, long g, long h, long i, long j)
//         { return a + b + c + d + e + f + g + h + i + j; }
//         exit(sum10(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
//
// Build:  make
// Run:    ./many_args; echo $?
// Exit status (echo $?): 55

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #1                  // arguments 1-8 in x0-x7
    mov x1, #2
    mov x2, #3
    mov x3, #4
    mov x4, #5
    mov x5, #6
    mov x6, #7
    mov x7, #8
    mov x9, #9                  // arguments 9 and 10 go on the stack:
    mov x10, #10                //   the 9th at [sp], the 10th at [sp, #8]
    stp x9, x10, [sp, #-16]!    // (16 bytes: sp stays aligned)
    bl sum10
    add sp, sp, #16             // the CALLER removes its stack arguments
    mov x16, #1
    svc #0x80

// long sum10(a..j): a-h in x0-x7; i at [sp], j at [sp, #8] on entry.
// A leaf, so sp does not move and the offsets stay as the caller left them.
sum10:
    add x0, x0, x1
    add x0, x0, x2
    add x0, x0, x3
    add x0, x0, x4
    add x0, x0, x5
    add x0, x0, x6
    add x0, x0, x7
    ldp x9, x10, [sp]           // the 9th and 10th arguments
    add x0, x0, x9
    add x0, x0, x10
    ret
