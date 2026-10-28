// args.s - print argc and every argv[i] (lesson 25, macOS)
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
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]

    mov w19, w0                 // w19 = argc (an int, 32 bits)
    mov x20, x1                 // x20 = argv (a pointer to an array of pointers)

    adrp x0, fmt_argc@PAGE
    add x0, x0, fmt_argc@PAGEOFF
    sub sp, sp, #16             // room for the variadic argument
    str x19, [sp]               // argc goes on the stack, not in x1
    bl _printf                  // printf("argc = %d\n", argc)
    add sp, sp, #16

    mov x21, #0                 // i = 0
main_loop:
    cmp x21, x19                // i < argc ?  (argc is never negative)
    b.ge main_done
    adrp x0, fmt_argv@PAGE
    add x0, x0, fmt_argv@PAGEOFF
    ldr x9, [x20, x21, lsl #3]  // argv[i]: 8-byte pointers, so scale by 8
    sub sp, sp, #16
    str x21, [sp]               // first variadic argument: i
    str x9, [sp, #8]            // second variadic argument: argv[i]
    bl _printf
    add sp, sp, #16
    add x21, x21, #1
    b main_loop

main_done:
    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
fmt_argc: .asciz "argc = %d\n"
fmt_argv: .asciz "argv[%d] = %s\n"
