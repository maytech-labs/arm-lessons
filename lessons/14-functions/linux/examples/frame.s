// frame.s - functions that call functions: sum of squares.
//
// C:      long square(long n) { return n * n; }
//         long sum_squares(long a, long b) { return square(a) + square(b); }
//         ... exit(sum_squares(3, 4));
//
// Build:  make
// Run:    ./frame; echo $?
// Debug:  gdb ./frame   then   break square   run   bt
// Exit status (echo $?): 25

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #3
    mov x1, #4
    bl sum_squares
    mov x8, #93                 // exit(sum_squares(3, 4))
    svc #0

// long sum_squares(long a, long b)
//   in:  x0 = a, x1 = b
//   out: x0 = a*a + b*b
// Frame (32 bytes):
//   [sp, #0]   saved x29
//   [sp, #8]   saved x30
//   [sp, #16]  b          (square may change x1, so keep b in memory)
//   [sp, #24]  square(a)
sum_squares:
    stp x29, x30, [sp, #-32]!   // reserve 32 bytes, save x29 and x30 at the bottom
    mov x29, sp
    str x1, [sp, #16]           // save b: we still need it after the first call

    bl square                   // x0 = square(a)
    str x0, [sp, #24]           // save it: the second call will overwrite x0

    ldr x0, [sp, #16]           // x0 = b
    bl square                   // x0 = square(b)

    ldr x1, [sp, #24]           // x1 = square(a)
    add x0, x0, x1              // result = square(a) + square(b)

    ldp x29, x30, [sp], #32     // restore and release the whole frame
    ret

// long square(long n): a leaf function, it calls nothing, so no frame needed
square:
    mul x0, x0, x0
    ret
