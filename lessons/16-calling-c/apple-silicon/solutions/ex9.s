// ex9.s - Exercise 16.9: void print_table(const char *title, const int *values, int n)
// (macOS).
//
// Build: make ex9        (clang -g -arch arm64 -o ex9 ex9_main.c ex9.s)
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

    .section __TEXT,__cstring
fmt:
    .asciz  "  [%d] = %d\n"

    .text
    .global _print_table
    .p2align 2
_print_table:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    sub     sp, sp, #16             // two variadic slots for printf

    mov     x19, x1                 // values
    mov     w20, w2                 // n
    mov     w21, #0                 // i
    bl      _puts                   // x0 is already title
table_loop:
    cmp     w21, w20                // while (i < n), signed: n is an int
    b.ge    table_done
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    ldrsw   x9, [x19, w21, uxtw #2] // values[i], sign-extended to fill the slot
    stp     x21, x9, [sp]           // slot 0 = i, slot 1 = values[i]
    bl      _printf
    add     w21, w21, #1
    b       table_loop
table_done:
    add     sp, sp, #16
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
