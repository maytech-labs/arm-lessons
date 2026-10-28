// triangles.s - triangles.c translated by hand (macOS version).
//
// Prints the first 5 triangle numbers and their sum.
// Build: make
// Run:   ./triangles
// Expected output:
//     T(1) = 1
//     T(2) = 3
//     T(3) = 6
//     T(4) = 10
//     T(5) = 15
//     sum = 35

    .section __TEXT,__cstring
fmt_t:
    .asciz "T(%d) = %ld\n"
fmt_sum:
    .asciz "sum = %ld\n"

    .text

// long print_triangles(int n)
//
// Variables and registers, as in the Linux version:
//     w19 = n, w20 = i, x21 = t, x22 = total   (all used after printf)
// Frame (48 bytes):
//     [sp, #0]  x29   [sp, #8]  x30
//     [sp, #16] x19   [sp, #24] x20
//     [sp, #32] x21   [sp, #40] x22
// Around each printf we also reserve 16 bytes for its two variadic
// arguments, which go on the stack on macOS.
    .global _print_triangles
    .p2align 2
_print_triangles:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov w19, w0                 // n = argument
    mov x22, #0                 // long total = 0;
    mov x21, #0                 // long t = 0;
    mov w20, #1                 // int i = 1;
loop:
    cmp w20, w19                // i <= n ?
    b.gt done                   // no: leave the loop
    add x21, x21, w20, sxtw     // t += i;   (i is int, t is long: sign-extend)
    adrp x0, fmt_t@PAGE         // printf("T(%d) = %ld\n", i, t);
    add x0, x0, fmt_t@PAGEOFF
    sub sp, sp, #16             // room for the two variadic arguments
    str w20, [sp]               // i in the first 8-byte slot
    str x21, [sp, #8]           // t in the second
    bl _printf
    add sp, sp, #16
    add x22, x22, x21           // total += t;
    add w20, w20, #1            // i++
    b loop
done:
    mov x0, x22                 // return total;

    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// int main(void)
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov w0, #5                  // long s = print_triangles(5);
    bl _print_triangles
    sub sp, sp, #16             // printf("sum = %ld\n", s);
    str x0, [sp]                //   s is variadic: on the stack
    adrp x0, fmt_sum@PAGE
    add x0, x0, fmt_sum@PAGEOFF
    bl _printf
    add sp, sp, #16
    mov w0, #0                  // return 0;

    ldp x29, x30, [sp], #16
    ret
