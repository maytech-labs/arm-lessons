// linecat.s - number the lines read from stdin (lesson 31 building block, macOS)
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
    .global _main
    .p2align 2
_main:
    // Frame: x29/x30, x19/x20, then the 1024-byte line buffer.
    sub sp, sp, #1056
    stp x29, x30, [sp]
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov w19, #0                 // n = 0

    // stdin is the libSystem variable __stdinp: find it through the GOT,
    // then load the FILE * it holds. It never changes, so keep it in x20.
    adrp x20, ___stdinp@GOTPAGE
    ldr x20, [x20, ___stdinp@GOTPAGEOFF]
    ldr x20, [x20]

loop:
    add x0, sp, #32             // line
    mov w1, #1024               // sizeof line
    mov x2, x20                 // stdin
    bl _fgets                    // NULL at end of file
    cbz x0, done
    add w19, w19, #1            // n++
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    add x9, sp, #32             // line
    sub sp, sp, #16
    stp x19, x9, [sp]           // variadic: n in slot 0, line in slot 1
    bl _printf
    add sp, sp, #16
    b loop

done:
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp]
    add sp, sp, #1056
    ret

    .section __TEXT,__cstring
fmt: .asciz "%4d: %s"
