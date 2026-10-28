// head.s - a head clone: print the first N lines (lesson 25)
//
// Usage: head [-n N] [FILE]     (N defaults to 10, FILE defaults to stdin)
//
// Build: make head
// Run:   ./head -n 3 sample.txt
// Expected output:
//   The quick brown fox
//   jumps over the lazy dog.
//   (an empty line)
// Run:   ./head sample.txt | tail -n 1
// Expected output (line 10 of the file):
//   five
// Run:   printf 'a\nb\nc\n' | ./head -n 2
// Expected output:
//   a
//   b
// Run:   ./head -n; echo $?
// Expected output (on stderr, then the status):
//   usage: head [-n N] [FILE]
//   2
//
// C version:
//   int main(int argc, char **argv) {
//       int n = 10, i = 1;
//       FILE *f = stdin;
//       char buf[256];
//       if (i < argc && strcmp(argv[i], "-n") == 0) {
//           if (i + 1 >= argc) { fputs("usage: head [-n N] [FILE]\n", stderr); return 2; }
//           n = atoi(argv[i + 1]);
//           i += 2;
//       }
//       if (i < argc) {
//           f = fopen(argv[i], "r");
//           if (f == NULL) { perror(argv[i]); return 1; }
//       }
//       while (n > 0 && fgets(buf, sizeof buf, f) != NULL) {
//           fputs(buf, stdout);
//           size_t len = strlen(buf);
//           if (buf[len - 1] == '\n') n--;   // only a full line counts
//       }
//       if (f != stdin) fclose(f);
//       return 0;
//   }

    .equ BUFSIZE, 256
    .equ BUF, 64                    // buf lives at sp + 64

    .text
    .global main
    .p2align 2
main:
    // frame: 16 (fp, lr) + 48 (x19..x24) + 256 (buf) = 320
    stp x29, x30, [sp, #-320]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]

    mov w19, w0                     // x19 = argc
    mov x20, x1                     // x20 = argv
    mov w21, #10                    // n = 10
    mov x22, #1                     // i = 1
    adrp x24, :got:stdin
    ldr x24, [x24, :got_lo12:stdin]
    ldr x24, [x24]                  // x24 = stdin
    mov x23, x24                    // f = stdin

    cmp x22, x19                    // i < argc ?
    b.ge main_file
    ldr x0, [x20, x22, lsl #3]
    adrp x1, opt_n
    add x1, x1, :lo12:opt_n
    bl strcmp
    cbnz w0, main_file              // not "-n": treat it as a file name
    add x9, x22, #1
    cmp x9, x19                     // i + 1 >= argc: "-n" without a number
    b.ge main_usage
    ldr x0, [x20, x9, lsl #3]
    bl atoi
    mov w21, w0                     // n = atoi(argv[i + 1])
    add x22, x22, #2                // i += 2

main_file:
    cmp x22, x19
    b.ge main_loop
    ldr x0, [x20, x22, lsl #3]
    adrp x1, mode_r
    add x1, x1, :lo12:mode_r
    bl fopen
    cbz x0, main_open_failed
    mov x23, x0                     // f = fopen(argv[i], "r")

main_loop:
    cmp w21, #0
    b.le main_end
    add x0, sp, #BUF
    mov w1, #BUFSIZE
    mov x2, x23
    bl fgets
    cbz x0, main_end
    adrp x1, :got:stdout
    ldr x1, [x1, :got_lo12:stdout]
    ldr x1, [x1]
    add x0, sp, #BUF
    bl fputs                        // fputs(buf, stdout)
    add x0, sp, #BUF
    bl strlen                       // fgets never gives an empty string
    add x9, sp, #BUF
    add x9, x9, x0
    ldrb w10, [x9, #-1]             // buf[len - 1] (a negative offset is fine)
    cmp w10, #'\n'
    b.ne main_loop
    sub w21, w21, #1                // a whole line: n--
    b main_loop

main_end:
    cmp x23, x24
    b.eq main_ok                    // never fclose(stdin)
    mov x0, x23
    bl fclose
main_ok:
    mov w0, #0
    b main_done

main_usage:
    adrp x1, :got:stderr
    ldr x1, [x1, :got_lo12:stderr]
    ldr x1, [x1]
    adrp x0, msg_usage
    add x0, x0, :lo12:msg_usage
    bl fputs
    mov w0, #2
    b main_done

main_open_failed:
    ldr x0, [x20, x22, lsl #3]
    bl perror
    mov w0, #1

main_done:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #320
    ret

    .section .rodata
opt_n:     .asciz "-n"
mode_r:    .asciz "r"
msg_usage: .asciz "usage: head [-n N] [FILE]\n"
