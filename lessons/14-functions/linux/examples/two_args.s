// two_args.s - a function with two arguments, called twice.
//
// C:      long max(long a, long b) { return a > b ? a : b; }
//         ... exit(max(max(17, 42), 30));
//
// Build:  make
// Run:    ./two_args; echo $?
// Exit status (echo $?): 42

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #17                 // first argument
    mov x1, #42                 // second argument
    bl max                      // x0 = max(17, 42)
    mov x1, #30                 // x0 is already the first argument
    bl max                      // x0 = max(x0, 30)
    mov x8, #93
    svc #0

// long max(long a, long b)
//   in:  x0 = a, x1 = b
//   out: x0 = the larger, as signed numbers
max:
    cmp x0, x1
    csel x0, x0, x1, gt
    ret
