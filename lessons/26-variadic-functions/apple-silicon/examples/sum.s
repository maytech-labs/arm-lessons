// sum.s - a variadic function written by hand on macOS: int sum(int n, ...).
//
// The C version:
//     int sum(int n, ...) {
//         va_list ap;
//         va_start(ap, n);
//         int total = 0;
//         for (int i = 0; i < n; i++)
//             total += va_arg(ap, int);
//         va_end(ap);
//         return total;
//     }
//
// On macOS every variadic argument is in an 8-byte stack slot starting at sp
// on entry, and va_list is just a pointer to the next slot. So:
//     va_start(ap, n)  ->  ap = sp on entry
//     va_arg(ap, int)  ->  value = *(int *)ap; ap += 8
// sum calls nothing, so it needs no frame at all.
//
// This file has no main. It is linked with the C test driver sum_test.c.
//
// Build and run:
//     make sum
//     ./sum
// Expected output:
//     sum(0) = 0
//     sum(3, 10, 20, 30) = 60
//     sum(7, 1..7) = 28
//     sum(10, 1..10) = 55
//     sum(4, -5, 100, -20, 1) = 76

    .text
    .globl  _sum
    .p2align 2
_sum:
    mov     x9, sp                  // va_start: x9 = ap = first variadic slot
    mov     w11, #0                 // total
loop:
    cmp     w0, #0
    b.le    done
    ldr     w10, [x9], #8           // va_arg(ap, int): load 4 bytes, step one slot
    add     w11, w11, w10
    sub     w0, w0, #1
    b       loop
done:
    mov     w0, w11
    ret
