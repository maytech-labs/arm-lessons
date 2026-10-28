// hello.s - print a line with puts() from the C library.
//
// C version:
//     int main(void) { puts("Hello from libc!"); return 0; }
//
// Build: make hello
// Run:   ./hello
// Expected output:
//     Hello from libc!
// Expected exit status: 0

    .section .rodata
msg:
    .asciz  "Hello from libc!"  // puts adds the newline itself

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!   // bl below overwrites x30: save it (and fp)
    mov     x29, sp

    adrp    x0, msg                 // x0 = first argument = address of msg
    add     x0, x0, :lo12:msg
    bl      puts                    // puts(msg)

    mov     w0, #0                  // return 0
    ldp     x29, x30, [sp], #16
    ret
