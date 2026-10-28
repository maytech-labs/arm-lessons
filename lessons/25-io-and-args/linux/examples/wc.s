// wc.s - a wc clone: count lines, words and bytes (lesson 25)
//
// Build: make wc
// Run:   ./wc sample.txt
// Expected output:
//   12 24 117 sample.txt
// Run:   printf 'one two\nthree\n' | ./wc
// Expected output:
//   2 3 14
//
// C version:
//   int main(int argc, char **argv) {
//       FILE *in = stdin;
//       if (argc > 1) {
//           in = fopen(argv[1], "r");
//           if (in == NULL) { perror(argv[1]); return 1; }
//       }
//       long lines = 0, words = 0, bytes = 0;
//       int inword = 0, c;
//       while ((c = fgetc(in)) != EOF) {
//           bytes++;
//           if (c == '\n') lines++;
//           if (c == ' ' || c == '\t' || c == '\n') inword = 0;
//           else if (!inword) { inword = 1; words++; }
//       }
//       if (argc > 1) {
//           printf("%ld %ld %ld %s\n", lines, words, bytes, argv[1]);
//           fclose(in);
//       } else {
//           printf("%ld %ld %ld\n", lines, words, bytes);
//       }
//       return 0;
//   }

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-80]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    str x25, [sp, #64]

    mov w25, w0                     // x25 = argc
    mov x24, x1                     // x24 = argv

    adrp x19, :got:stdin
    ldr x19, [x19, :got_lo12:stdin]
    ldr x19, [x19]                  // in = stdin
    cmp w25, #1
    b.le main_count
    ldr x0, [x24, #8]               // in = fopen(argv[1], "r")
    adrp x1, mode_r
    add x1, x1, :lo12:mode_r
    bl fopen
    cbz x0, main_open_failed
    mov x19, x0

main_count:
    mov x20, #0                     // lines
    mov x21, #0                     // words
    mov x22, #0                     // bytes
    mov w23, #0                     // inword
main_loop:
    mov x0, x19
    bl fgetc
    cmn w0, #1                      // EOF?
    b.eq main_report
    add x22, x22, #1                // bytes++
    cmp w0, #'\n'
    b.ne main_not_newline
    add x20, x20, #1                // lines++
main_not_newline:
    cmp w0, #' '
    b.eq main_space
    cmp w0, #'\t'
    b.eq main_space
    cmp w0, #'\n'
    b.eq main_space
    cbnz w23, main_loop             // already inside a word
    mov w23, #1                     // a word starts here
    add x21, x21, #1
    b main_loop
main_space:
    mov w23, #0
    b main_loop

main_report:
    cmp w25, #1
    b.le main_report_stdin
    adrp x0, fmt_file
    add x0, x0, :lo12:fmt_file
    mov x1, x20
    mov x2, x21
    mov x3, x22
    ldr x4, [x24, #8]               // argv[1]
    bl printf
    mov x0, x19
    bl fclose
    b main_ok
main_report_stdin:
    adrp x0, fmt_stdin
    add x0, x0, :lo12:fmt_stdin
    mov x1, x20
    mov x2, x21
    mov x3, x22
    bl printf
main_ok:
    mov w0, #0
    b main_done

main_open_failed:
    ldr x0, [x24, #8]
    bl perror
    mov w0, #1

main_done:
    ldr x25, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #80
    ret

    .section .rodata
mode_r:    .asciz "r"
fmt_file:  .asciz "%ld %ld %ld %s\n"
fmt_stdin: .asciz "%ld %ld %ld\n"
