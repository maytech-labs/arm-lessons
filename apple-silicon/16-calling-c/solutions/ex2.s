// ex2.s - Exercise 16.2: print two lines with puts (macOS).
//
// Build: make ex2
// Run:   ./ex2; echo $?
// Expected output:
//     Line one
//     Line two
// Expected exit status: 0

    .section __TEXT,__cstring
line1:
    .asciz  "Line one"
line2:
    .asciz  "Line two"

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, line1@PAGE
    add     x0, x0, line1@PAGEOFF
    bl      _puts
    adrp    x0, line2@PAGE          // x0 was destroyed by puts: load it again
    add     x0, x0, line2@PAGEOFF
    bl      _puts

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
