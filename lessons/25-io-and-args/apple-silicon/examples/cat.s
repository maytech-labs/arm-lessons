// cat.s - a cat clone: copy files (or stdin) to stdout (lesson 25, macOS)
//
// Build: make cat
// Run:   ./cat sample.txt
// Expected output: the 12 lines of sample.txt
// Run:   printf 'piped\n' | ./cat
// Expected output:
//   piped
// Run:   ./cat nope.txt sample.txt > /dev/null; echo $?
// Expected output (on stderr, then the status):
//   nope.txt: No such file or directory
//   1
//
// C version:
//   void cat_stream(FILE *in) {
//       int c;                              // int, not char: EOF is -1
//       while ((c = fgetc(in)) != EOF)
//           fputc(c, stdout);
//   }
//   int main(int argc, char **argv) {
//       int status = 0;
//       if (argc == 1) { cat_stream(stdin); return 0; }
//       for (int i = 1; i < argc; i++) {
//           FILE *f = fopen(argv[i], "r");
//           if (f == NULL) { perror(argv[i]); status = 1; continue; }
//           cat_stream(f);
//           fclose(f);
//       }
//       return status;
//   }

    .text
    .global _main
    .p2align 2

// void cat_stream(FILE *in)
cat_stream:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                     // x19 = in
    adrp x20, ___stdoutp@GOTPAGE
    ldr x20, [x20, ___stdoutp@GOTPAGEOFF]
    ldr x20, [x20]                  // x20 = stdout (the FILE *)
cat_stream_loop:
    mov x0, x19
    bl _fgetc                        // w0 = next byte (0..255) or EOF (-1)
    cmn w0, #1                      // compare w0 with -1
    b.eq cat_stream_done
    mov x1, x20
    bl _fputc                        // fputc(c, stdout); c is already in w0
    b cat_stream_loop
cat_stream_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

_main:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    str x23, [sp, #48]

    mov w19, w0                     // x19 = argc
    mov x20, x1                     // x20 = argv
    mov w22, #0                     // status = 0

    cmp w19, #1
    b.ne main_files
    adrp x0, ___stdinp@GOTPAGE
    ldr x0, [x0, ___stdinp@GOTPAGEOFF]
    ldr x0, [x0]                    // x0 = stdin
    bl cat_stream
    b main_done

main_files:
    mov x21, #1                     // i = 1
main_loop:
    cmp x21, x19
    b.ge main_done
    ldr x0, [x20, x21, lsl #3]      // argv[i]
    adrp x1, mode_r@PAGE
    add x1, x1, mode_r@PAGEOFF
    bl _fopen
    cbz x0, main_open_failed
    mov x23, x0                     // x23 = f
    bl cat_stream
    mov x0, x23
    bl _fclose
    b main_next
main_open_failed:
    ldr x0, [x20, x21, lsl #3]
    bl _perror                       // "argv[i]: reason"
    mov w22, #1                     // status = 1, but keep going
main_next:
    add x21, x21, #1
    b main_loop

main_done:
    mov w0, w22
    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

    .section __TEXT,__cstring
mode_r: .asciz "r"
