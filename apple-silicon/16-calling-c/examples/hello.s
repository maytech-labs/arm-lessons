// hello.s - print a line with puts() from libSystem (macOS).
//
// C version:
//     int main(void) { puts("Hello from libc!"); return 0; }
//
// Build: make hello
// Run:   ./hello
// Expected output:
//     Hello from libc!
// Expected exit status: 0

    .section __TEXT,__cstring
msg:
    .asciz  "Hello from libc!"  // puts adds the newline itself

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!   // bl below overwrites x30: save it (and fp)
    mov     x29, sp

    adrp    x0, msg@PAGE            // x0 = first argument = address of msg
    add     x0, x0, msg@PAGEOFF
    bl      _puts                   // C's puts is _puts

    mov     w0, #0                  // return 0
    ldp     x29, x30, [sp], #16
    ret
