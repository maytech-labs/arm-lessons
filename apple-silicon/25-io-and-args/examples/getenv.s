// getenv.s - look up one environment variable by name (lesson 25, macOS)
//
// Build: make getenv
// Run:   GREETING=hello ./getenv
// Expected output:
//   GREETING is hello
// Run:   env -u GREETING ./getenv
// Expected output:
//   GREETING is not set
//
// C version:
//   int main(void) {
//       char *v = getenv("GREETING");
//       if (v == NULL) puts("GREETING is not set");
//       else printf("GREETING is %s\n", v);
//       return 0;
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, name@PAGE
    add x0, x0, name@PAGEOFF
    bl _getenv                   // x0 = pointer to the value, or NULL
    cbz x0, main_unset

    sub sp, sp, #16             // printf("GREETING is %s\n", v)
    str x0, [sp]                // v goes on the stack
    adrp x0, fmt_set@PAGE
    add x0, x0, fmt_set@PAGEOFF
    bl _printf
    add sp, sp, #16
    b main_done

main_unset:
    adrp x0, msg_unset@PAGE
    add x0, x0, msg_unset@PAGEOFF
    bl _puts

main_done:
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
name:      .asciz "GREETING"
fmt_set:   .asciz "GREETING is %s\n"
msg_unset: .asciz "GREETING is not set"
