// ex5.s - reduce an array with a two-argument function: sum, max, product (lesson 24, exercise 24.5, macOS)
//
// Build: make ex5
// Run:   ./ex5
// Expected output:
//   sum = 19
//   max = 9
//   product = -504
//
// The C version:
//   long reduce(const long *a, long n, long init, long (*f)(long, long)) {
//       long acc = init;
//       for (long i = 0; i < n; i++) acc = f(acc, a[i]);
//       return acc;
//   }
//   long add(long a, long b) { return a + b; }
//   long max(long a, long b) { return a > b ? a : b; }
//   long mul(long a, long b) { return a * b; }
//   long nums[5] = {4, -2, 9, 7, 1};
//   int main(void) {
//       printf("sum = %ld\n",     reduce(nums, 5, 0, add));
//       printf("max = %ld\n",     reduce(nums, 5, nums[0], max));
//       printf("product = %ld\n", reduce(nums, 5, 1, mul));
//   }

    .equ N, 5

    .text
    .global _main
    .p2align 2

add_long:
    add x0, x0, x1
    ret
max_long:
    cmp  x0, x1
    csel x0, x0, x1, gt
    ret
mul_long:
    mul x0, x0, x1
    ret

// long reduce(const long *a, long n, long init, long (*f)(long, long))
reduce:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    str x23, [sp, #48]
    mov x19, x0                     // a
    mov x20, x1                     // n
    mov x21, x3                     // f
    mov x22, x2                     // acc = init
    mov x23, #0                     // i
reduce_loop:
    cmp x23, x20
    b.ge reduce_done
    mov x0, x22                     // acc = f(acc, a[i])
    ldr x1, [x19, x23, lsl #3]
    blr x21
    mov x22, x0
    add x23, x23, #1
    b   reduce_loop
reduce_done:
    mov x0, x22
    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// void report(const char *fmt, long init, long (*f)(long, long))
report:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                     // fmt
    sub sp, sp, #16                 // room for printf's variadic arguments
    mov x3, x2                      // f
    mov x2, x1                      // init
    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #N
    bl   reduce
    str  x0, [sp]                   // the result is printf's variadic argument
    mov  x0, x19
    bl   _printf
    add sp, sp, #16
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, fmt_sum@PAGE
    add  x0, x0, fmt_sum@PAGEOFF
    mov  x1, #0
    adr  x2, add_long
    bl   report

    adrp x0, fmt_max@PAGE
    add  x0, x0, fmt_max@PAGEOFF
    adrp x1, nums@PAGE
    ldr  x1, [x1, nums@PAGEOFF]     // init = nums[0]
    adr  x2, max_long
    bl   report

    adrp x0, fmt_product@PAGE
    add  x0, x0, fmt_product@PAGEOFF
    mov  x1, #1
    adr  x2, mul_long
    bl   report

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__const
    .p2align 3
nums:        .quad 4, -2, 9, 7, 1

    .section __TEXT,__cstring
fmt_sum:     .asciz "sum = %ld\n"
fmt_max:     .asciz "max = %ld\n"
fmt_product: .asciz "product = %ld\n"
