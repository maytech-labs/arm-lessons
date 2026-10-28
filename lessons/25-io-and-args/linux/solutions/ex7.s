// ex7.s - a tiny grep: print the lines that contain a word (lesson 25)
//
// Usage: ex7 WORD [FILE]       (FILE defaults to stdin)
// Exit status: 0 if some line matched, 1 if none did, 2 on a usage or open error.
//
// Build: make ex7
// Run:   ./ex7 the ../examples/sample.txt; echo $?
// Expected output:
//   jumps over the lazy dog.
//   with the lid off.
//   0
// Run:   ./ex7 zebra ../examples/sample.txt; echo $?
// Expected output:
//   1
// Run:   printf 'cat\ndog\ncatalog\n' | ./ex7 cat
// Expected output:
//   cat
//   catalog
//
// C version:
//   int main(int argc, char **argv) {
//       if (argc < 2 || argc > 3) { fputs("usage: ex7 WORD [FILE]\n", stderr); return 2; }
//       FILE *f = stdin;
//       if (argc == 3) {
//           f = fopen(argv[2], "r");
//           if (f == NULL) { perror(argv[2]); return 2; }
//       }
//       char buf[256];
//       int status = 1;
//       while (fgets(buf, sizeof buf, f) != NULL)
//           if (strstr(buf, argv[1]) != NULL) { fputs(buf, stdout); status = 0; }
//       if (f != stdin) fclose(f);
//       return status;
//   }

    .equ BUFSIZE, 256
    .equ BUF, 64

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-320]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = argc, x20 = argv
    stp x21, x22, [sp, #32]         // x21 = f, x22 = status
    stp x23, x24, [sp, #48]         // x23 = stdin, x24 = stdout

    mov w19, w0
    mov x20, x1
    cmp w19, #2
    b.lt main_usage
    cmp w19, #3
    b.gt main_usage

    adrp x23, :got:stdin
    ldr x23, [x23, :got_lo12:stdin]
    ldr x23, [x23]
    adrp x24, :got:stdout
    ldr x24, [x24, :got_lo12:stdout]
    ldr x24, [x24]

    mov x21, x23                    // f = stdin
    cmp w19, #3
    b.ne main_search
    ldr x0, [x20, #16]
    adrp x1, mode_r
    add x1, x1, :lo12:mode_r
    bl fopen
    cbz x0, main_open_failed
    mov x21, x0

main_search:
    mov w22, #1                     // status = 1 (no match yet)
main_loop:
    add x0, sp, #BUF
    mov w1, #BUFSIZE
    mov x2, x21
    bl fgets
    cbz x0, main_end
    add x0, sp, #BUF
    ldr x1, [x20, #8]               // argv[1]
    bl strstr                       // pointer to the first match, or NULL
    cbz x0, main_loop
    add x0, sp, #BUF
    mov x1, x24
    bl fputs
    mov w22, #0
    b main_loop

main_end:
    cmp x21, x23
    b.eq main_ret_status
    mov x0, x21
    bl fclose
main_ret_status:
    mov w0, w22
    b main_done

main_open_failed:
    ldr x0, [x20, #16]
    bl perror
    mov w0, #2
    b main_done

main_usage:
    adrp x1, :got:stderr
    ldr x1, [x1, :got_lo12:stderr]
    ldr x1, [x1]
    adrp x0, msg_usage
    add x0, x0, :lo12:msg_usage
    bl fputs
    mov w0, #2

main_done:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #320
    ret

    .section .rodata
mode_r:    .asciz "r"
msg_usage: .asciz "usage: ex7 WORD [FILE]\n"
