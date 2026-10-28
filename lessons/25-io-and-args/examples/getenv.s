// getenv.s - look up one environment variable by name (lesson 25)
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
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, name
    add x0, x0, :lo12:name
    bl getenv                   // x0 = pointer to the value, or NULL
    cbz x0, main_unset

    mov x1, x0                  // printf("GREETING is %s\n", v)
    adrp x0, fmt_set
    add x0, x0, :lo12:fmt_set
    bl printf
    b main_done

main_unset:
    adrp x0, msg_unset
    add x0, x0, :lo12:msg_unset
    bl puts

main_done:
    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
name:      .asciz "GREETING"
fmt_set:   .asciz "GREETING is %s\n"
msg_unset: .asciz "GREETING is not set"
