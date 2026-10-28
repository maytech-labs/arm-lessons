// printf_args.s - call printf with several arguments, the macOS way.
//
// C version:
//     int main(void) {
//         printf("%d + %d = %d\n", 2, 3, 5);
//         printf("%s is %ld years old\n", "Ada", 36L);
//         return 0;
//     }
//
// On macOS, every argument after printf's format string (the "..." part)
// goes on the stack, one 8-byte slot each, starting at [sp].
// The format string itself is a normal argument and stays in x0.
//
// Build: make printf_args
// Run:   ./printf_args
// Expected output:
//     2 + 3 = 5
//     Ada is 36 years old

    .section __TEXT,__cstring
fmt_sum:
    .asciz  "%d + %d = %d\n"
fmt_age:
    .asciz  "%s is %ld years old\n"
name:
    .asciz  "Ada"

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #32             // room for 3 slots, rounded up to 16

    adrp    x0, fmt_sum@PAGE        // format string: in x0 as usual
    add     x0, x0, fmt_sum@PAGEOFF
    mov     x9, #2
    str     x9, [sp]                // 1st variadic argument: slot 0
    mov     x9, #3
    str     x9, [sp, #8]            // 2nd: slot 1
    mov     x9, #5
    str     x9, [sp, #16]           // 3rd: slot 2
    bl      _printf

    adrp    x0, fmt_age@PAGE
    add     x0, x0, fmt_age@PAGEOFF
    adrp    x9, name@PAGE
    add     x9, x9, name@PAGEOFF
    str     x9, [sp]                // %s: the pointer, slot 0
    mov     x9, #36
    str     x9, [sp, #8]            // %ld: slot 1
    bl      _printf

    add     sp, sp, #32             // give the argument area back
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
