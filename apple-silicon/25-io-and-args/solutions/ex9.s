// ex9.s - wc for several files, with a total line (lesson 25, macOS)
//
// Usage: ex9 [FILE...]          (no files: count stdin)
//
// Build: make ex9
// Run:   (cd ../examples && ../solutions/ex9 sample.txt sample.txt)
// Expected output:
//   12 24 117 sample.txt
//   12 24 117 sample.txt
//   24 48 234 total
// Run:   printf 'one two\nthree\n' | ./ex9
// Expected output:
//   2 3 14
// Run:   ./ex9 nope.txt ../examples/sample.txt; echo $?
// Expected output (perror on stderr, then the count, then the status):
//   nope.txt: No such file or directory
//   12 24 117 ../examples/sample.txt
//   1
// (only one file was counted, so no total line)
//
// C version:
//   struct counts { long lines, words, bytes; };
//   void count_stream(FILE *in, struct counts *c) {
//       int ch, inword = 0;
//       c->lines = c->words = c->bytes = 0;
//       while ((ch = fgetc(in)) != EOF) {
//           c->bytes++;
//           if (ch == '\n') c->lines++;
//           if (ch == ' ' || ch == '\t' || ch == '\n') inword = 0;
//           else if (!inword) { inword = 1; c->words++; }
//       }
//   }
//   int main(int argc, char **argv) {
//       struct counts c, total = {0, 0, 0};
//       int status = 0, counted = 0;
//       if (argc == 1) {
//           count_stream(stdin, &c);
//           printf("%ld %ld %ld\n", c.lines, c.words, c.bytes);
//           return 0;
//       }
//       for (int i = 1; i < argc; i++) {
//           FILE *f = fopen(argv[i], "r");
//           if (f == NULL) { perror(argv[i]); status = 1; continue; }
//           count_stream(f, &c);
//           fclose(f);
//           printf("%ld %ld %ld %s\n", c.lines, c.words, c.bytes, argv[i]);
//           total.lines += c.lines; total.words += c.words; total.bytes += c.bytes;
//           counted++;
//       }
//       if (counted > 1)
//           printf("%ld %ld %ld total\n", total.lines, total.words, total.bytes);
//       return status;
//   }

    // struct counts
    .equ C_LINES, 0
    .equ C_WORDS, 8
    .equ C_BYTES, 16
    .equ C_SIZE,  24

    .text
    .global _main
    .p2align 2

// void count_stream(FILE *in, struct counts *c)
count_stream:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = in, x20 = c
    stp x21, x22, [sp, #32]         // x21 = lines, x22 = words
    stp x23, x24, [sp, #48]         // x23 = bytes, x24 = inword
    mov x19, x0
    mov x20, x1
    mov x21, #0
    mov x22, #0
    mov x23, #0
    mov w24, #0
count_loop:
    mov x0, x19
    bl _fgetc
    cmn w0, #1
    b.eq count_done
    add x23, x23, #1
    cmp w0, #'\n'
    b.ne count_not_newline
    add x21, x21, #1
count_not_newline:
    cmp w0, #' '
    b.eq count_space
    cmp w0, #'\t'
    b.eq count_space
    cmp w0, #'\n'
    b.eq count_space
    cbnz w24, count_loop
    mov w24, #1
    add x22, x22, #1
    b count_loop
count_space:
    mov w24, #0
    b count_loop
count_done:
    str x21, [x20, #C_LINES]
    str x22, [x20, #C_WORDS]
    str x23, [x20, #C_BYTES]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// main's frame: fp/lr, x19..x24, then struct c at sp+64, total at sp+88
    .equ C_OFF, 64
    .equ TOTAL_OFF, 88
_main:
    stp x29, x30, [sp, #-128]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = argc, x20 = argv
    stp x21, x22, [sp, #32]         // x21 = i, x22 = status
    stp x23, x24, [sp, #48]         // x23 = counted, x24 = f
    mov w19, w0
    mov x20, x1

    cmp w19, #1
    b.ne main_files
    adrp x0, ___stdinp@GOTPAGE
    ldr x0, [x0, ___stdinp@GOTPAGEOFF]
    ldr x0, [x0]
    add x1, sp, #C_OFF
    bl count_stream
    adrp x0, fmt_stdin@PAGE
    add x0, x0, fmt_stdin@PAGEOFF
    ldr x1, [sp, #C_OFF + C_LINES]
    ldr x2, [sp, #C_OFF + C_WORDS]
    ldr x3, [sp, #C_OFF + C_BYTES]
    sub sp, sp, #32                 // variadic arguments go on the stack
    stp x1, x2, [sp]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32
    mov w0, #0
    b main_done

main_files:
    str xzr, [sp, #TOTAL_OFF + C_LINES]
    str xzr, [sp, #TOTAL_OFF + C_WORDS]
    str xzr, [sp, #TOTAL_OFF + C_BYTES]
    mov w22, #0
    mov w23, #0
    mov x21, #1
main_loop:
    cmp x21, x19
    b.ge main_total
    ldr x0, [x20, x21, lsl #3]
    adrp x1, mode_r@PAGE
    add x1, x1, mode_r@PAGEOFF
    bl _fopen
    cbz x0, main_open_failed
    mov x24, x0
    add x1, sp, #C_OFF
    bl count_stream
    mov x0, x24
    bl _fclose
    adrp x0, fmt_file@PAGE
    add x0, x0, fmt_file@PAGEOFF
    ldr x1, [sp, #C_OFF + C_LINES]
    ldr x2, [sp, #C_OFF + C_WORDS]
    ldr x3, [sp, #C_OFF + C_BYTES]
    ldr x4, [x20, x21, lsl #3]
    sub sp, sp, #32                 // variadic arguments go on the stack
    stp x1, x2, [sp]
    stp x3, x4, [sp, #16]
    bl _printf
    add sp, sp, #32
    // total += c, field by field
    ldr x9, [sp, #C_OFF + C_LINES]
    ldr x10, [sp, #TOTAL_OFF + C_LINES]
    add x10, x10, x9
    str x10, [sp, #TOTAL_OFF + C_LINES]
    ldr x9, [sp, #C_OFF + C_WORDS]
    ldr x10, [sp, #TOTAL_OFF + C_WORDS]
    add x10, x10, x9
    str x10, [sp, #TOTAL_OFF + C_WORDS]
    ldr x9, [sp, #C_OFF + C_BYTES]
    ldr x10, [sp, #TOTAL_OFF + C_BYTES]
    add x10, x10, x9
    str x10, [sp, #TOTAL_OFF + C_BYTES]
    add w23, w23, #1
    b main_next
main_open_failed:
    ldr x0, [x20, x21, lsl #3]
    bl _perror
    mov w22, #1
main_next:
    add x21, x21, #1
    b main_loop

main_total:
    cmp w23, #1
    b.le main_status
    adrp x0, fmt_total@PAGE
    add x0, x0, fmt_total@PAGEOFF
    ldr x1, [sp, #TOTAL_OFF + C_LINES]
    ldr x2, [sp, #TOTAL_OFF + C_WORDS]
    ldr x3, [sp, #TOTAL_OFF + C_BYTES]
    sub sp, sp, #32                 // variadic arguments go on the stack
    stp x1, x2, [sp]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32
main_status:
    mov w0, w22

main_done:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #128
    ret

    .section __TEXT,__cstring
mode_r:    .asciz "r"
fmt_stdin: .asciz "%ld %ld %ld\n"
fmt_file:  .asciz "%ld %ld %ld %s\n"
fmt_total: .asciz "%ld %ld %ld total\n"
