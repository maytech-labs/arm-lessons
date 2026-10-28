// args.s - print argc and every argv[i] (lesson 25)
//
// Build: make args
// Run:   ./args hello "two words" 3
// Expected output:
//   argc = 4
//   argv[0] = ./args
//   argv[1] = hello
//   argv[2] = two words
//   argv[3] = 3
//
// C version:
//   int main(int argc, char **argv) {
//       printf("argc = %d\n", argc);
//       for (int i = 0; i < argc; i++)
//           printf("argv[%d] = %s\n", i, argv[i]);
//       return 0;
//   }

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]

    mov w19, w0                 // w19 = argc (an int, 32 bits)
    mov x20, x1                 // x20 = argv (a pointer to an array of pointers)

    adrp x0, fmt_argc
    add x0, x0, :lo12:fmt_argc
    mov w1, w19
    bl printf                   // printf("argc = %d\n", argc)

    mov x21, #0                 // i = 0
main_loop:
    cmp x21, x19                // i < argc ?  (argc is never negative)
    b.ge main_done
    adrp x0, fmt_argv
    add x0, x0, :lo12:fmt_argv
    mov w1, w21                 // i
    ldr x2, [x20, x21, lsl #3]  // argv[i]: 8-byte pointers, so scale by 8
    bl printf
    add x21, x21, #1
    b main_loop

main_done:
    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section .rodata
fmt_argc: .asciz "argc = %d\n"
fmt_argv: .asciz "argv[%d] = %s\n"
