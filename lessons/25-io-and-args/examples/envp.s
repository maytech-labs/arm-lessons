// envp.s - walk the environment through main's third argument (lesson 25)
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
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    mov x19, x2                 // x19 = p = envp (third argument)
    mov x20, #0                 // n = 0
main_loop:
    ldr x0, [x19]               // x0 = *p
    cbz x0, main_done           // the array ends with a NULL pointer
    bl puts
    add x20, x20, #1
    add x19, x19, #8            // p++ (next pointer)
    b main_loop

main_done:
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    mov x1, x20
    bl printf

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
fmt: .asciz "%d variables\n"
