// ex3.s - Exercise 14.3: max3(a, b, c) built from a leaf max(a, b).
//
// C:      long max(long a, long b) { return a > b ? a : b; }
//         long max3(long a, long b, long c) { return max(max(a, b), c); }
//         ... exit(max3(12, 99, 57));
//
// Build:  make
// Run:    ./ex3; echo $?
// Exit status (echo $?): 99

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #12
    mov x1, #99
    mov x2, #57
    bl max3
    mov x8, #93
    svc #0

// long max3(long a, long b, long c): calls max, so it saves x29/x30.
// c is needed after the first call, and max might change x2, so c is kept
// in the frame.
max3:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x2, [sp, #16]           // save c
    bl max                      // x0 = max(a, b)
    ldr x1, [sp, #16]           // x1 = c
    bl max                      // x0 = max(x0, c)
    ldp x29, x30, [sp], #32
    ret

// long max(long a, long b): leaf
max:
    cmp x0, x1
    csel x0, x0, x1, gt
    ret
