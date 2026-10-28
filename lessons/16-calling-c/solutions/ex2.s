// ex2.s - Exercise 16.2: print two lines with puts.
//
// Build: make ex2
// Run:   ./ex2; echo $?
// Expected output:
//     Line one
//     Line two
// Expected exit status: 0

    .section .rodata
line1:
    .asciz  "Line one"
line2:
    .asciz  "Line two"

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, line1
    add     x0, x0, :lo12:line1
    bl      puts
    adrp    x0, line2               // x0 was destroyed by puts: load it again
    add     x0, x0, :lo12:line2
    bl      puts

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
