// ex8.s - a uniq clone: drop adjacent duplicate lines from stdin (lesson 25, macOS)
//
// Build: make ex8
// Run:   printf 'a\na\nb\na\na\na\nc\n' | ./ex8
// Expected output:
//   a
//   b
//   a
//   c
//
// C version:
//   static char buf1[256], buf2[256];
//   int main(void) {
//       char *prev = buf1, *cur = buf2;
//       int first = 1;
//       while (fgets(cur, 256, stdin) != NULL) {
//           if (first || strcmp(cur, prev) != 0) fputs(cur, stdout);
//           first = 0;
//           char *t = prev; prev = cur; cur = t;   // swap: no copying needed
//       }
//       return 0;
//   }

    .equ BUFSIZE, 256

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = prev, x20 = cur
    stp x21, x22, [sp, #32]         // x21 = first, x22 = stdin
    str x23, [sp, #48]              // x23 = stdout

    adrp x19, buf1@PAGE
    add x19, x19, buf1@PAGEOFF
    adrp x20, buf2@PAGE
    add x20, x20, buf2@PAGEOFF
    mov w21, #1
    adrp x22, ___stdinp@GOTPAGE
    ldr x22, [x22, ___stdinp@GOTPAGEOFF]
    ldr x22, [x22]
    adrp x23, ___stdoutp@GOTPAGE
    ldr x23, [x23, ___stdoutp@GOTPAGEOFF]
    ldr x23, [x23]

main_loop:
    mov x0, x20
    mov w1, #BUFSIZE
    mov x2, x22
    bl _fgets
    cbz x0, main_done
    cbnz w21, main_print            // the first line is always new
    mov x0, x20
    mov x1, x19
    bl _strcmp
    cbz w0, main_swap               // same as the previous line: skip it
main_print:
    mov x0, x20
    mov x1, x23
    bl _fputs
main_swap:
    mov w21, #0
    mov x9, x19                     // swap the two pointers
    mov x19, x20
    mov x20, x9
    b main_loop

main_done:
    mov w0, #0
    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

    .bss
buf1: .space BUFSIZE
buf2: .space BUFSIZE
