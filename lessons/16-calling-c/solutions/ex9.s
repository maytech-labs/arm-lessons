// ex9.s - Exercise 16.9: void print_table(const char *title, const int *values, int n)
//
// C version:
//     void print_table(const char *title, const int *values, int n) {
//         puts(title);
//         for (int i = 0; i < n; i++)
//             printf("  [%d] = %d\n", i, values[i]);
//     }
//
// Build: make ex9        (gcc -g -o ex9 ex9_main.c ex9.s)
// Run:   ./ex9
// Expected output:
//     Primes
//       [0] = 2
//       [1] = 3
//       [2] = 5
//       [3] = 7
//     Temperatures
//       [0] = -3
//       [1] = 0
//       [2] = 12

    .section .rodata
fmt:
    .asciz  "  [%d] = %d\n"

    .text
    .global print_table
    .p2align 2
print_table:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]

    mov     x19, x1                 // values
    mov     w20, w2                 // n
    mov     w21, #0                 // i
    bl      puts                    // x0 is already title
table_loop:
    cmp     w21, w20                // while (i < n), signed: n is an int
    b.ge    table_done
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    mov     w1, w21
    ldr     w2, [x19, w21, uxtw #2] // values[i]: 4-byte ints, so scale by 4
    bl      printf
    add     w21, w21, #1
    b       table_loop
table_done:
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
