// wc.s - count lines, words and bytes (lesson 31, project 1)
//
// Build: make
// Run:   printf 'hello world\nfoo\n' | ./wc
// Expected output:
//          2       3      16
// Run:   ./wc -lw FILE...      (any of -l -w -c, separate or combined)
// Tests: ../../tests/check.sh wc ./wc     (from this directory)
//
// C version (abridged):
//   static char buf[65536];
//   static int flags;                 // bit 0 = -l, bit 1 = -w, bit 2 = -c
//   static long cur[3], total[3];     // lines, words, bytes
//
//   void count_stream(FILE *f, long *c) {
//       long lines = 0, words = 0, bytes = 0; int inword = 0; size_t n;
//       while ((n = fread(buf, 1, sizeof buf, f)) > 0) {
//           bytes += n;
//           for (size_t i = 0; i < n; i++) {
//               unsigned char ch = buf[i];
//               if (ch == '\n') lines++;
//               if (ch == ' ' || (ch >= '\t' && ch <= '\r')) inword = 0;
//               else if (!inword) { inword = 1; words++; }
//           }
//       }
//       c[0] = lines; c[1] = words; c[2] = bytes;
//   }
//
//   void print_counts(long *c, const char *name) {
//       for (int i = 0; i < 3; i++)
//           if (flags & (1 << i)) printf("%8ld", c[i]);
//       if (name) printf(" %s", name);
//       putchar('\n');
//   }
//
//   int main(int argc, char **argv) {
//       int i = 1, status = 0;
//       for (; i < argc && argv[i][0] == '-' && argv[i][1] != 0; i++)
//           for (char *p = argv[i] + 1; *p; p++) {
//               if (*p == 'l') flags |= 1;
//               else if (*p == 'w') flags |= 2;
//               else if (*p == 'c') flags |= 4;
//               else {
//                   fprintf(stderr, "wc: unknown option -%c\n", *p);
//                   fputs("usage: wc [-l] [-w] [-c] [file...]\n", stderr);
//                   return 2;
//               }
//           }
//       if (flags == 0) flags = 7;
//       int nfiles = argc - i;
//       if (nfiles == 0) { count_stream(stdin, cur); print_counts(cur, NULL); return 0; }
//       for (; i < argc; i++) {
//           FILE *f = fopen(argv[i], "r");
//           if (!f) {
//               fprintf(stderr, "wc: %s: %s\n", argv[i], strerror(errno));
//               status = 1;
//               continue;
//           }
//           count_stream(f, cur);
//           fclose(f);
//           print_counts(cur, argv[i]);
//           for (int k = 0; k < 3; k++) total[k] += cur[k];
//       }
//       if (nfiles > 1) print_counts(total, "total");
//       return status;
//   }

    .equ BUFSIZE, 65536

    .text

// ---------------------------------------------------------------------------
// void count_stream(FILE *f, long *c)
//   x19 = f, x20 = c, x21 = lines, x22 = words, x23 = bytes, x24 = inword
// ---------------------------------------------------------------------------
    .p2align 2
count_stream:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    mov x19, x0
    mov x20, x1
    mov x21, #0
    mov x22, #0
    mov x23, #0
    mov x24, #0

cs_read:
    adrp x0, buf
    add x0, x0, :lo12:buf
    mov x1, #1
    mov x2, #BUFSIZE
    mov x3, x19
    bl fread                    // x0 = bytes read, 0 at end of file
    cbz x0, cs_done
    add x23, x23, x0

    // Scan the chunk. Only temporaries here: no calls inside this loop.
    adrp x9, buf
    add x9, x9, :lo12:buf       // x9 = p
    add x10, x9, x0             // x10 = end
cs_byte:
    ldrb w11, [x9], #1          // ch = *p++
    cmp w11, #'\n'
    cinc x21, x21, eq           // lines += (ch == '\n')
    cmp w11, #' '
    b.eq cs_space
    sub w12, w11, #9            // '\t'..'\r' are 9..13
    cmp w12, #4
    b.ls cs_space
    cbnz x24, cs_next           // already inside a word
    mov x24, #1
    add x22, x22, #1            // a new word starts here
    b cs_next
cs_space:
    mov x24, #0
cs_next:
    cmp x9, x10
    b.lo cs_byte
    b cs_read

cs_done:
    stp x21, x22, [x20]         // c[0] = lines, c[1] = words
    str x23, [x20, #16]         // c[2] = bytes
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// ---------------------------------------------------------------------------
// void print_counts(long *c, const char *name)
//   x19 = c, x20 = name, x21 = i, w22 = flags
// ---------------------------------------------------------------------------
    .p2align 2
print_counts:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0
    mov x20, x1
    adrp x9, flags
    ldr w22, [x9, :lo12:flags]
    mov x21, #0
pc_loop:
    lsr w9, w22, w21            // test bit i of flags
    tbz w9, #0, pc_skip
    adrp x0, fmt_count
    add x0, x0, :lo12:fmt_count
    ldr x1, [x19, x21, lsl #3]  // c[i]
    bl printf
pc_skip:
    add x21, x21, #1
    cmp x21, #3
    b.lo pc_loop

    cbz x20, pc_newline
    adrp x0, fmt_name
    add x0, x0, :lo12:fmt_name
    mov x1, x20
    bl printf
pc_newline:
    mov w0, #'\n'
    bl putchar
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// ---------------------------------------------------------------------------
// int main(int argc, char **argv)
//   w19 = argc, x20 = argv, w21 = i, w22 = status, w23 = nfiles, x24 = name / FILE*
// ---------------------------------------------------------------------------
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    mov w19, w0
    mov x20, x1
    mov w21, #1
    mov w22, #0

    // --- options -----------------------------------------------------------
    adrp x10, flags
    add x10, x10, :lo12:flags   // x10 = &flags (no calls until we use it)
opt_arg:
    cmp w21, w19
    b.ge opt_done
    ldr x9, [x20, w21, sxtw #3] // x9 = argv[i]
    ldrb w11, [x9]
    cmp w11, #'-'
    b.ne opt_done
    ldrb w11, [x9, #1]
    cbz w11, opt_done           // a lone "-" is a file name
    add x9, x9, #1
opt_char:
    ldrb w11, [x9], #1
    cbz w11, opt_next_arg
    ldr w12, [x10]
    mov w13, #1
    cmp w11, #'l'
    b.eq opt_set
    mov w13, #2
    cmp w11, #'w'
    b.eq opt_set
    mov w13, #4
    cmp w11, #'c'
    b.eq opt_set
    b bad_option                // w11 = the bad character
opt_set:
    orr w12, w12, w13
    str w12, [x10]
    b opt_char
opt_next_arg:
    add w21, w21, #1
    b opt_arg

opt_done:
    ldr w12, [x10]
    cbnz w12, 1f
    mov w12, #7                 // no flags means -l -w -c
    str w12, [x10]
1:
    sub w23, w19, w21           // nfiles = argc - i
    cbnz w23, file_loop

    // --- no files: read stdin ------------------------------------------------
    adrp x0, :got:stdin
    ldr x0, [x0, :got_lo12:stdin]
    ldr x0, [x0]                // x0 = stdin (the FILE *)
    adrp x1, cur
    add x1, x1, :lo12:cur
    bl count_stream
    adrp x0, cur
    add x0, x0, :lo12:cur
    mov x1, #0
    bl print_counts
    b main_done

    // --- one file at a time ----------------------------------------------------
file_loop:
    cmp w21, w19
    b.ge files_done
    ldr x0, [x20, w21, sxtw #3] // argv[i]
    adrp x1, mode_r
    add x1, x1, :lo12:mode_r
    bl fopen
    cbnz x0, file_opened

    bl __errno_location
    ldr w0, [x0]
    bl strerror                 // x0 = message
    mov x3, x0
    adrp x0, :got:stderr
    ldr x0, [x0, :got_lo12:stderr]
    ldr x0, [x0]
    adrp x1, fmt_open
    add x1, x1, :lo12:fmt_open
    ldr x2, [x20, w21, sxtw #3]
    bl fprintf                  // "wc: NAME: reason\n"
    mov w22, #1
    b file_next

file_opened:
    mov x24, x0                 // keep the FILE * across calls
    adrp x1, cur
    add x1, x1, :lo12:cur
    bl count_stream
    mov x0, x24
    bl fclose
    adrp x0, cur
    add x0, x0, :lo12:cur
    ldr x1, [x20, w21, sxtw #3]
    bl print_counts

    // total[k] += cur[k] for k = 0, 1, 2
    adrp x9, cur
    add x9, x9, :lo12:cur
    adrp x10, total
    add x10, x10, :lo12:total
    ldp x11, x12, [x9]
    ldp x13, x14, [x10]
    add x13, x13, x11
    add x14, x14, x12
    stp x13, x14, [x10]
    ldr x11, [x9, #16]
    ldr x13, [x10, #16]
    add x13, x13, x11
    str x13, [x10, #16]
file_next:
    add w21, w21, #1
    b file_loop

files_done:
    cmp w23, #1
    b.le main_done
    adrp x0, total
    add x0, x0, :lo12:total
    adrp x1, name_total
    add x1, x1, :lo12:name_total
    bl print_counts

main_done:
    mov w0, w22
main_ret:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

bad_option:
    adrp x0, :got:stderr
    ldr x0, [x0, :got_lo12:stderr]
    ldr x0, [x0]
    adrp x1, fmt_badopt
    add x1, x1, :lo12:fmt_badopt
    mov w2, w11
    bl fprintf
    adrp x0, msg_usage
    add x0, x0, :lo12:msg_usage
    adrp x1, :got:stderr
    ldr x1, [x1, :got_lo12:stderr]
    ldr x1, [x1]
    bl fputs
    mov w0, #2
    b main_ret

    .section .rodata
mode_r:     .asciz "r"
fmt_count:  .asciz "%8ld"
fmt_name:   .asciz " %s"
fmt_open:   .asciz "wc: %s: %s\n"
fmt_badopt: .asciz "wc: unknown option -%c\n"
msg_usage:  .asciz "usage: wc [-l] [-w] [-c] [file...]\n"
name_total: .asciz "total"

    .data
    .p2align 2
flags:  .word 0

    .bss
    .p2align 3
cur:    .space 24
total:  .space 24
buf:    .space BUFSIZE
