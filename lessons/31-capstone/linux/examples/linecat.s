// linecat.s - number the lines read from stdin (lesson 31 building block)
//
// Build: make linecat
// Run:   ./linecat < poem.txt
// Expected output:
//      1: The quick brown fox
//      2: jumps over
//      3: the lazy dog.
//      4:          ("   4: ", with a trailing space)
//      5: It was not amused.
//
// The pattern every line-oriented tool uses: a buffer on the stack, fgets in
// a loop until it returns NULL, then work on one line at a time.
//
// C version:
//   int main(void) {
//       char line[1024];
//       int n = 0;
//       while (fgets(line, sizeof line, stdin) != NULL) {
//           n++;
//           printf("%4d: %s", n, line);   // line still ends in '\n'
//       }
//       return 0;
//   }

    .text
    .global main
    .p2align 2
main:
    // Frame: x29/x30, x19/x20, then the 1024-byte line buffer.
    sub sp, sp, #1056
    stp x29, x30, [sp]
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov w19, #0                 // n = 0

    // stdin is a variable inside libc: find it through the GOT, then load
    // the FILE * it holds. It never changes, so keep it in x20.
    adrp x20, :got:stdin
    ldr x20, [x20, :got_lo12:stdin]
    ldr x20, [x20]

loop:
    add x0, sp, #32             // line
    mov w1, #1024               // sizeof line
    mov x2, x20                 // stdin
    bl fgets                    // NULL at end of file
    cbz x0, done
    add w19, w19, #1            // n++
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    mov w1, w19
    add x2, sp, #32
    bl printf
    b loop

done:
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp]
    add sp, sp, #1056
    ret

    .section .rodata
fmt: .asciz "%4d: %s"
