// ex2.s - an echo clone: print the arguments separated by spaces (lesson 25)
//
// Build: make ex2
// Run:   ./ex2 hello   "big world"
// Expected output:
//   hello big world
// Run:   ./ex2
// Expected output: one empty line
//
// C version:
//   int main(int argc, char **argv) {
//       for (int i = 1; i < argc; i++) {
//           if (i > 1) putchar(' ');
//           fputs(argv[i], stdout);
//       }
//       putchar('\n');
//       return 0;
//   }

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov w19, w0                     // argc
    mov x20, x1                     // argv
    adrp x22, :got:stdout
    ldr x22, [x22, :got_lo12:stdout]
    ldr x22, [x22]                  // x22 = stdout

    mov x21, #1                     // i = 1
main_loop:
    cmp x21, x19
    b.ge main_done
    cmp x21, #1
    b.eq main_no_space
    mov w0, #' '
    bl putchar
main_no_space:
    ldr x0, [x20, x21, lsl #3]
    mov x1, x22
    bl fputs                        // fputs(argv[i], stdout): no newline added
    add x21, x21, #1
    b main_loop

main_done:
    mov w0, #'\n'
    bl putchar
    mov w0, #0
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
