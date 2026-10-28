// ex5.s - exercise 26.5: void die(const char *fmt, ...) prints "fatal: ",
// the formatted message and a newline to stderr, then exits with status 3.
//
// The C version:
//     void die(const char *fmt, ...) {
//         va_list ap;
//         va_start(ap, fmt);
//         fputs("fatal: ", stderr);
//         vfprintf(stderr, fmt, ap);
//         va_end(ap);
//         fputc('\n', stderr);
//         exit(3);
//     }
//
// Build and run:
//     make ex5
//     ./ex5; echo $?
// Expected output (on stderr), then the exit status:
//     fatal: cannot open data.txt (attempt 3 of 5, waited 1.5 s)
//     3

    .equ VA_STACK,    0
    .equ VA_GR_TOP,   8
    .equ VA_VR_TOP,  16
    .equ VA_GR_OFFS, 24
    .equ VA_VR_OFFS, 28

// Frame (256 bytes), the same plan as logmsg in examples/vforward.s:
//     sp+0 x29/x30, sp+16 x19, sp+32 va_list, sp+64 x1..x7 (ends sp+120),
//     sp+128 q0..q7 (ends sp+256), sp+256 entry sp
    .equ AP,        32
    .equ GR_SAVE,   64
    .equ GR_TOP,   120
    .equ VR_SAVE,  128
    .equ VR_TOP,   256
    .equ FRAME,    256

    .text
    .global die
    .p2align 2
die:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0                         // fmt
    stp     x1, x2, [sp, #GR_SAVE]
    stp     x3, x4, [sp, #GR_SAVE + 16]
    stp     x5, x6, [sp, #GR_SAVE + 32]
    str     x7, [sp, #GR_SAVE + 48]
    stp     q0, q1, [sp, #VR_SAVE]
    stp     q2, q3, [sp, #VR_SAVE + 32]
    stp     q4, q5, [sp, #VR_SAVE + 64]
    stp     q6, q7, [sp, #VR_SAVE + 96]
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]
    add     x9, sp, #GR_TOP
    str     x9, [sp, #AP + VA_GR_TOP]
    add     x9, sp, #VR_TOP
    str     x9, [sp, #AP + VA_VR_TOP]
    mov     w9, #-56
    str     w9, [sp, #AP + VA_GR_OFFS]
    mov     w9, #-128
    str     w9, [sp, #AP + VA_VR_OFFS]

    adrp    x0, prefix
    add     x0, x0, :lo12:prefix
    adrp    x1, :got:stderr
    ldr     x1, [x1, :got_lo12:stderr]
    ldr     x1, [x1]
    bl      fputs                           // fputs("fatal: ", stderr)

    adrp    x0, :got:stderr
    ldr     x0, [x0, :got_lo12:stderr]
    ldr     x0, [x0]
    mov     x1, x19
    add     x2, sp, #AP                     // &ap
    bl      vfprintf                        // vfprintf(stderr, fmt, ap)

    mov     w0, #'\n'
    adrp    x1, :got:stderr
    ldr     x1, [x1, :got_lo12:stderr]
    ldr     x1, [x1]
    bl      fputc                           // fputc('\n', stderr)

    mov     w0, #3
    bl      exit                            // never returns, so no epilogue

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    adrp    x1, fname
    add     x1, x1, :lo12:fname             // %s
    mov     w2, #3                          // %d
    mov     w3, #5                          // %d
    fmov    d0, #1.5                        // %.1f
    bl      die
    // not reached
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
prefix: .asciz  "fatal: "
fmt:    .asciz  "cannot open %s (attempt %d of %d, waited %.1f s)"
fname:  .asciz  "data.txt"
