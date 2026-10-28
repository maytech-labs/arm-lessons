// streams.s - write to stdout and stderr, return an exit status (lesson 25)
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
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // stdout is a global variable inside libc that holds a FILE *.
    // We find the variable's address through the GOT, then load its value.
    adrp x8, :got:stdout
    ldr x8, [x8, :got_lo12:stdout]  // x8 = &stdout
    ldr x1, [x8]                    // x1 = stdout (the FILE *)
    adrp x0, msg_out
    add x0, x0, :lo12:msg_out
    bl fputs

    adrp x8, :got:stderr
    ldr x8, [x8, :got_lo12:stderr]  // x8 = &stderr
    ldr x1, [x8]                    // x1 = stderr
    adrp x0, msg_err
    add x0, x0, :lo12:msg_err
    bl fputs

    mov w0, #3                      // exit status 3
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
msg_out: .asciz "to stdout\n"
msg_err: .asciz "to stderr\n"
