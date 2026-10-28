// ex3.s - print the arguments in reverse order, one per line (lesson 25, macOS)
//
// Build: make ex3
// Run:   ./ex3 a b c
// Expected output:
//   c
//   b
//   a
//
// C version:
//   int main(int argc, char **argv) {
//       for (int i = argc - 1; i >= 1; i--)
//           puts(argv[i]);
//       return 0;
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    mov x20, x1                     // argv
    sub w19, w0, #1                 // i = argc - 1 (writing w19 zeroes the top of x19)
main_loop:
    cmp x19, #1
    b.lt main_done
    ldr x0, [x20, x19, lsl #3]
    bl _puts
    sub x19, x19, #1
    b main_loop

main_done:
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
