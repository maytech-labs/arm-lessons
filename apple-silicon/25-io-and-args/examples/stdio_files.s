// stdio_files.s - write a file with fprintf, read it back with fgets (lesson 25, macOS)
//
// Build: make stdio_files
// Run:   ./stdio_files
// Expected output:
//   read: line 1
//   read: line 2
//   read: line 3
// It also leaves out.txt behind (cat out.txt shows "line 1" .. "line 3").
// make clean deletes it.
//
// C version:
//   int main(void) {
//       FILE *f = fopen("out.txt", "w");
//       if (f == NULL) { perror("out.txt"); return 1; }
//       for (int i = 1; i <= 3; i++)
//           fprintf(f, "line %d\n", i);
//       fclose(f);
//
//       char buf[128];
//       f = fopen("out.txt", "r");
//       if (f == NULL) { perror("out.txt"); return 1; }
//       while (fgets(buf, sizeof buf, f) != NULL)
//           printf("read: %s", buf);      // buf already ends in '\n'
//       fclose(f);
//       return 0;
//   }

    .equ BUFSIZE, 128

    .text
    .global _main
    .p2align 2
_main:
    // frame: 16 (fp, lr) + 16 (x19, x20) + 128 (buf) = 160
    stp x29, x30, [sp, #-160]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    // buf is at sp + 32 .. sp + 159

    adrp x0, path@PAGE
    add x0, x0, path@PAGEOFF
    adrp x1, mode_w@PAGE
    add x1, x1, mode_w@PAGEOFF
    bl _fopen                    // f = fopen("out.txt", "w")
    cbz x0, main_fail
    mov x19, x0                 // x19 = f

    mov w20, #1                 // i = 1
main_write_loop:
    cmp w20, #3
    b.gt main_write_done
    mov x0, x19                 // fprintf(f, "line %d\n", i)
    adrp x1, fmt_line@PAGE
    add x1, x1, fmt_line@PAGEOFF
    sub sp, sp, #16             // fprintf is variadic after the format:
    str x20, [sp]               // i goes on the stack (f and the format stay in x0, x1)
    bl _fprintf
    add sp, sp, #16
    add w20, w20, #1
    b main_write_loop
main_write_done:
    mov x0, x19
    bl _fclose                   // flushes the buffer to the file

    adrp x0, path@PAGE
    add x0, x0, path@PAGEOFF
    adrp x1, mode_r@PAGE
    add x1, x1, mode_r@PAGEOFF
    bl _fopen                    // f = fopen("out.txt", "r")
    cbz x0, main_fail
    mov x19, x0

main_read_loop:
    add x0, sp, #32             // fgets(buf, BUFSIZE, f)
    mov w1, #BUFSIZE
    mov x2, x19
    bl _fgets                    // returns buf, or NULL at end of file
    cbz x0, main_read_done
    sub sp, sp, #16             // printf("read: %s", buf)
    str x0, [sp]
    adrp x0, fmt_read@PAGE
    add x0, x0, fmt_read@PAGEOFF
    bl _printf
    add sp, sp, #16
    b main_read_loop
main_read_done:
    mov x0, x19
    bl _fclose
    mov w0, #0
    b main_done

main_fail:
    adrp x0, path@PAGE
    add x0, x0, path@PAGEOFF
    bl _perror
    mov w0, #1

main_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #160
    ret

    .section __TEXT,__cstring
path:     .asciz "out.txt"
mode_w:   .asciz "w"
mode_r:   .asciz "r"
fmt_line: .asciz "line %d\n"
fmt_read: .asciz "read: %s"
