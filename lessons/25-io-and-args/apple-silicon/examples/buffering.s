// buffering.s - stdio buffers output; write() does not wait (lesson 25, macOS)
//
// Build: make buffering
// Run:   ./buffering
// Expected output (on a terminal and through a pipe alike):
//   B
//   AC
//
// C version:
//   int main(void) {
//       printf("A");             // goes into stdout's buffer, not to the screen yet
//       write(1, "B\n", 2);      // system call wrapper: goes out immediately
//       printf("C\n");           // more buffer
//       return 0;                // returning from main flushes stdout: "AC\n" appears
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, str_a@PAGE
    add x0, x0, str_a@PAGEOFF
    bl _printf                  // printf("A")

    mov w0, #1                  // write(1, "B\n", 2): libSystem's thin wrapper
    adrp x1, str_b@PAGE         // around the write system call, no buffer
    add x1, x1, str_b@PAGEOFF
    mov x2, #2
    bl _write

    adrp x0, str_c@PAGE
    add x0, x0, str_c@PAGEOFF
    bl _printf                  // printf("C\n")

    mov w0, #0                  // return 0: exit() flushes stdout
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
str_a: .asciz "A"
str_b: .asciz "B\n"              // __cstring holds only NUL-terminated strings
str_c: .asciz "C\n"
