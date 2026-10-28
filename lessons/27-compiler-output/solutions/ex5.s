// ex5.s - Exercise 27.5: reverse an int array in place.
//
//     void reverse(int *a, long n) {
//         long i = 0, j = n - 1;
//         while (i < j) {
//             int tmp = a[i];
//             a[i] = a[j];
//             a[j] = tmp;
//             i++;
//             j--;
//         }
//     }
//
//     void print_array(const int *a, long n) {
//         for (long i = 0; i < n; i++)
//             printf("%d%c", a[i], i == n - 1 ? '\n' : ' ');
//     }
//
// Build: make
// Run:   ./ex5
// Expected output:
//     1 2 3 4 5 6 7
//     7 6 5 4 3 2 1
//     -5 10
//     10 -5

    .section .rodata
fmt:
    .asciz "%d%c"

    .data
    .p2align 2
seven:
    .word 1, 2, 3, 4, 5, 6, 7
two:
    .word -5, 10

    .text

// void reverse(int *a, long n)
// Leaf. x0 = a, x1 = n. Use two pointers instead of two indexes, like the
// compiler would: x2 = &a[i], x3 = &a[j].
    .global reverse
    .type reverse, %function
reverse:
    cmp x1, #2
    b.lt 2f                     // fewer than 2 elements: nothing to swap
    mov x2, x0                  // lo = &a[0]
    sub x1, x1, #1
    add x3, x0, x1, lsl #2      // hi = &a[n - 1]
1:
    ldr w4, [x2]                // tmp = *lo
    ldr w5, [x3]
    str w5, [x2], #4            // *lo++ = *hi
    str w4, [x3], #-4           // *hi-- = tmp
    cmp x2, x3
    b.lo 1b                     // while (lo < hi)
2:
    ret
    .size reverse, .-reverse

// void print_array(const int *a, long n)
// a, n and i are all used after printf: x19 = a, x20 = n, x21 = i.
// Frame: 16 + 24 = 40, rounded up to 48.
    .global print_array
    .type print_array, %function
print_array:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, x0
    mov x20, x1
    mov x21, #0                 // i = 0
    cmp x20, #0
    b.le 2f                     // guard
1:
    ldr w1, [x19, x21, lsl #2]  // a[i]
    sub x9, x20, #1
    cmp x21, x9                 // i == n - 1 ?
    mov w9, #'\n'
    mov w10, #' '
    csel w2, w9, w10, eq        // the ternary
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    add x21, x21, #1
    cmp x21, x20
    b.lt 1b
2:
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
    .size print_array, .-print_array

// Print an array, reverse it, print it again.
// x19 = a, x20 = n (both used after calls). Frame: 16 + 16 = 32.
    .type show_reverse, %function
show_reverse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
    bl print_array              // print_array(a, n)
    mov x0, x19
    mov x1, x20
    bl reverse                  // reverse(a, n)
    mov x0, x19
    mov x1, x20
    bl print_array              // print_array(a, n)
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
    .size show_reverse, .-show_reverse

    .global main
    .type main, %function
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, seven
    add x0, x0, :lo12:seven
    mov x1, #7
    bl show_reverse
    adrp x0, two
    add x0, x0, :lo12:two
    mov x1, #2
    bl show_reverse
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
    .size main, .-main
