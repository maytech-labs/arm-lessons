// streams.s - write to stdout and stderr, return an exit status (lesson 25, macOS)
//
// Build: make streams
// Run:   ./streams; echo $?
// Expected output (on a terminal):
//   to stdout
//   to stderr
//   3
// Run:   ./streams 2>/dev/null
// Expected output (stderr thrown away):
//   to stdout
//
// C version:
//   int main(void) {
//       fputs("to stdout\n", stdout);
//       fputs("to stderr\n", stderr);
//       return 3;
//   }

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // In <stdio.h> on macOS, stdout is a macro for __stdoutp, a global variable
    // in libSystem that holds a FILE *. In assembly it gets one more underscore:
    // ___stdoutp. We find its address through the GOT, then load its value.
    adrp x8, ___stdoutp@GOTPAGE
    ldr x8, [x8, ___stdoutp@GOTPAGEOFF]  // x8 = &__stdoutp
    ldr x1, [x8]                    // x1 = stdout (the FILE *)
    adrp x0, msg_out@PAGE
    add x0, x0, msg_out@PAGEOFF
    bl _fputs

    adrp x8, ___stderrp@GOTPAGE
    ldr x8, [x8, ___stderrp@GOTPAGEOFF]  // x8 = &__stderrp
    ldr x1, [x8]                    // x1 = stderr
    adrp x0, msg_err@PAGE
    add x0, x0, msg_err@PAGEOFF
    bl _fputs

    mov w0, #3                      // exit status 3
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
msg_out: .asciz "to stdout\n"
msg_err: .asciz "to stderr\n"
