// ex4.s - add up the integer arguments (lesson 25, macOS)
//
// Build: make ex4
// Run:   ./ex4 10 20 -5
// Expected output:
//   sum = 25
// Run:   ./ex4
// Expected output:
//   sum = 0
//
// C version:
//   int main(int argc, char **argv) {
//       long sum = 0;
//       for (int i = 1; i < argc; i++)
//           sum += atoi(argv[i]);
//       printf("sum = %ld\n", sum);
//       return 0;
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov w19, w0                     // argc
    mov x20, x1                     // argv
    mov x21, #1                     // i
    mov x22, #0                     // sum
main_loop:
    cmp x21, x19
    b.ge main_done
    ldr x0, [x20, x21, lsl #3]
    bl _atoi                         // w0 = int value
    add x22, x22, w0, sxtw          // sum += (long)value: sign-extend the int
    add x21, x21, #1
    b main_loop

main_done:
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16
    str x22, [sp]                   // variadic: on the stack
    bl _printf
    add sp, sp, #16
    mov w0, #0
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
fmt: .asciz "sum = %ld\n"
