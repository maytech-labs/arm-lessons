// ex5.s - Exercise 27.5: reverse an int array in place (macOS).
//
//     void reverse(int *a, long n);        // two pointers moving inwards
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

    .section __TEXT,__cstring
fmt:
    .asciz "%d%c"

    .data
    .p2align 2
seven:
    .word 1, 2, 3, 4, 5, 6, 7
two:
    .word -5, 10

    .text

// void reverse(int *a, long n): leaf. x2 = &a[i], x3 = &a[j].
    .global _reverse
    .p2align 2
_reverse:
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

// void print_array(const int *a, long n)
// x19 = a, x20 = n, x21 = i (all used after printf). Frame 48.
    .global _print_array
    .p2align 2
_print_array:
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
    ldr w9, [x19, x21, lsl #2]  // a[i]
    sub x10, x20, #1
    cmp x21, x10                // i == n - 1 ?
    mov w10, #'\n'
    mov w11, #' '
    csel w10, w10, w11, eq      // the ternary
    sub sp, sp, #16             // both arguments are variadic: stack
    str w9, [sp]
    str w10, [sp, #8]
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    bl _printf
    add sp, sp, #16
    add x21, x21, #1
    cmp x21, x20
    b.lt 1b
2:
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// Print an array, reverse it, print it again.
// x19 = a, x20 = n (both used after calls). Frame: 16 + 16 = 32.
    .p2align 2
show_reverse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
    bl _print_array
    mov x0, x19
    mov x1, x20
    bl _reverse
    mov x0, x19
    mov x1, x20
    bl _print_array
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, seven@PAGE
    add x0, x0, seven@PAGEOFF
    mov x1, #7
    bl show_reverse
    adrp x0, two@PAGE
    add x0, x0, two@PAGEOFF
    mov x1, #2
    bl show_reverse
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
