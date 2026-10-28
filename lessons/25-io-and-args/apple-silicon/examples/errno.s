// errno.s - a failing fopen, errno, and perror (lesson 25, macOS)
//
// Build: make errno
// Run:   ./errno 2>&1; echo $?
// Expected output:
//   no-such-file.txt: No such file or directory
//   errno = 2
//   1
//
// C version:
//   int main(void) {
//       FILE *f = fopen("no-such-file.txt", "r");
//       if (f == NULL) {
//           int e = errno;               // save it before calling anything else
//           perror("no-such-file.txt");  // to stderr: "<name>: <reason>"
//           printf("errno = %d\n", e);
//           return 1;
//       }
//       fclose(f);
//       return 0;
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    adrp x0, path@PAGE
    add x0, x0, path@PAGEOFF
    adrp x1, mode_r@PAGE
    add x1, x1, mode_r@PAGEOFF
    bl _fopen                    // x0 = FILE *, or NULL on failure
    cbnz x0, main_opened

    // errno is not a plain global: each thread has its own. libSystem gives
    // us its address through a function: int *__error(void).
    bl ___error         // x0 = &errno
    ldr w19, [x0]               // w19 = errno (an int)

    adrp x0, path@PAGE
    add x0, x0, path@PAGEOFF
    bl _perror                   // prints "no-such-file.txt: No such file or directory"

    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #16
    str x19, [sp]               // variadic: on the stack
    bl _printf
    add sp, sp, #16

    mov w0, #1                  // failure
    b main_done

main_opened:
    bl _fclose                   // x0 is still the FILE *
    mov w0, #0

main_done:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
path:   .asciz "no-such-file.txt"
mode_r: .asciz "r"
fmt:    .asciz "errno = %d\n"
