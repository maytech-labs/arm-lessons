// envp.s - walk the environment through main's third argument (lesson 25, macOS)
//
// Build: make envp
// Run:   env -i A=1 B=two ./envp
//        (env -i starts the program with an empty environment plus A and B)
// Expected output:
//   A=1
//   B=two
//   2 variables
//
// C version:
//   int main(int argc, char **argv, char **envp) {
//       int n = 0;
//       for (char **p = envp; *p != NULL; p++) { puts(*p); n++; }
//       printf("%d variables\n", n);
//       return 0;
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    mov x19, x2                 // x19 = p = envp (third argument)
    mov x20, #0                 // n = 0
main_loop:
    ldr x0, [x19]               // x0 = *p
    cbz x0, main_done           // the array ends with a NULL pointer
    bl _puts
    add x20, x20, #1
    add x19, x19, #8            // p++ (next pointer)
    b main_loop

main_done:
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16
    str x20, [sp]               // variadic: on the stack
    bl _printf
    add sp, sp, #16

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt: .asciz "%d variables\n"
