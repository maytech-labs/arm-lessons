// printf_args.s - call printf with several arguments.
//
// C version:
//     int main(void) {
//         printf("%d + %d = %d\n", 2, 3, 5);
//         printf("%s is %ld years old\n", "Ada", 36L);
//         return 0;
//     }
//
// On Linux, printf's extra arguments go in x1, x2, x3, ... exactly like
// the arguments of any other function.
//
// Build: make printf_args
// Run:   ./printf_args
// Expected output:
//     2 + 3 = 5
//     Ada is 36 years old

    .section .rodata
fmt_sum:
    .asciz  "%d + %d = %d\n"
fmt_age:
    .asciz  "%s is %ld years old\n"
name:
    .asciz  "Ada"

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, fmt_sum             // 1st argument: the format string
    add     x0, x0, :lo12:fmt_sum
    mov     w1, #2                  // 2nd argument: an int, so a w register
    mov     w2, #3                  // 3rd
    mov     w3, #5                  // 4th
    bl      printf

    adrp    x0, fmt_age
    add     x0, x0, :lo12:fmt_age
    adrp    x1, name                // %s wants a pointer
    add     x1, x1, :lo12:name
    mov     x2, #36                 // %ld wants a long, so an x register
    bl      printf

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
