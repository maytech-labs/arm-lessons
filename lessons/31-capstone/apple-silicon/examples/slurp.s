// slurp.s - read a whole file into one heap buffer (lesson 31 building block, macOS)
//
// Build: make slurp
// Run:   ./slurp poem.txt
// Expected output:
//   65 bytes
//   The quick brown fox
//   jumps over
//   the lazy dog.
//
//   It was not amused.
// Run:   ./slurp nope.txt; echo $?
// Expected output (on stderr, then the status):
//   nope.txt: No such file or directory
//   1
//
// Programs like an interpreter or Game of Life want the whole input in memory
// at once. fseek to the end, ftell gives the size, fseek back, one fread.
//
// C version:
//   int main(int argc, char **argv) {
//       if (argc != 2) { fputs("usage: slurp FILE\n", stderr); return 2; }
//       FILE *f = fopen(argv[1], "rb");
//       if (f == NULL) { perror(argv[1]); return 1; }
//       fseek(f, 0, SEEK_END);
//       long size = ftell(f);
//       fseek(f, 0, SEEK_SET);
//       char *buf = malloc(size + 1);
//       size_t n = fread(buf, 1, size, f);
//       buf[n] = '\0';                    // now it is also a C string
//       fclose(f);
//       printf("%ld bytes\n", (long)n);
//       fwrite(buf, 1, n, stdout);
//       free(buf);
//       return 0;
//   }

    .equ SEEK_SET, 0
    .equ SEEK_END, 2

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]     // x19 = FILE *, x20 = buf
    stp x21, x22, [sp, #32]     // x21 = size, then n; x22 = argv
    mov x22, x1

    cmp w0, #2
    b.eq open_file
    adrp x0, msg_usage@PAGE
    add x0, x0, msg_usage@PAGEOFF
    adrp x1, ___stderrp@GOTPAGE
    ldr x1, [x1, ___stderrp@GOTPAGEOFF]
    ldr x1, [x1]
    bl _fputs
    mov w0, #2
    b done

open_file:
    ldr x0, [x22, #8]           // argv[1]
    adrp x1, mode_rb@PAGE
    add x1, x1, mode_rb@PAGEOFF
    bl _fopen
    mov x19, x0
    cbnz x19, opened
    ldr x0, [x22, #8]
    bl _perror                   // "NAME: reason" on stderr
    mov w0, #1
    b done

opened:
    mov x0, x19
    mov x1, #0
    mov w2, #SEEK_END
    bl _fseek
    mov x0, x19
    bl _ftell
    mov x21, x0                 // size
    mov x0, x19
    mov x1, #0
    mov w2, #SEEK_SET
    bl _fseek

    add x0, x21, #1
    bl _malloc
    mov x20, x0                 // buf (a real program checks for NULL)

    mov x0, x20
    mov x1, #1
    mov x2, x21
    mov x3, x19
    bl _fread
    mov x21, x0                 // n = bytes actually read
    strb wzr, [x20, x21]        // buf[n] = '\0'
    mov x0, x19
    bl _fclose

    adrp x0, fmt_bytes@PAGE
    add x0, x0, fmt_bytes@PAGEOFF
    sub sp, sp, #16
    str x21, [sp]               // variadic: n, on the stack
    bl _printf
    add sp, sp, #16

    mov x0, x20
    mov x1, #1
    mov x2, x21
    adrp x3, ___stdoutp@GOTPAGE
    ldr x3, [x3, ___stdoutp@GOTPAGEOFF]
    ldr x3, [x3]
    bl _fwrite
    mov x0, x20
    bl _free
    mov w0, #0

done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
mode_rb:   .asciz "rb"
fmt_bytes: .asciz "%ld bytes\n"
msg_usage: .asciz "usage: slurp FILE\n"
