// triangles.s - triangles.c translated by hand, using the recipe in the lesson.
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

    .section .rodata
fmt_t:
    .asciz "T(%d) = %ld\n"
fmt_sum:
    .asciz "sum = %ld\n"

    .text

// long print_triangles(int n)
//
// Step 2, the variables:   n, i, t, total
// Step 3, where they live: all four are used after the printf call,
//                          so all four go in callee-saved registers:
//                              w19 = n, w20 = i, x21 = t, x22 = total
// Step 4, the frame (48 bytes):
//     [sp, #0]  x29   [sp, #8]  x30
//     [sp, #16] x19   [sp, #24] x20
//     [sp, #32] x21   [sp, #40] x22
    .global print_triangles
    .type print_triangles, %function
print_triangles:
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
    adrp x0, fmt_t              // printf("T(%d) = %ld\n", i, t);
    add x0, x0, :lo12:fmt_t
    mov w1, w20
    mov x2, x21
    bl printf
    add x22, x22, x21           // total += t;
    add w20, w20, #1            // i++
    b loop
done:
    mov x0, x22                 // return total;

    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
    .size print_triangles, .-print_triangles

// int main(void)
    .global main
    .type main, %function
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov w0, #5                  // long s = print_triangles(5);
    bl print_triangles
    mov x1, x0                  // printf("sum = %ld\n", s);
    adrp x0, fmt_sum
    add x0, x0, :lo12:fmt_sum
    bl printf
    mov w0, #0                  // return 0;

    ldp x29, x30, [sp], #16
    ret
    .size main, .-main
