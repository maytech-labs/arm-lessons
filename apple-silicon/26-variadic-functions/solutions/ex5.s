// ex5.s - exercise 26.5 (macOS): void die(const char *fmt, ...) prints
// "fatal: ", the formatted message and a newline to stderr, then exit(3).
//
// Build and run:
//     make ex5
//     ./ex5; echo $?
// Expected output (on stderr), then the exit status:
//     fatal: cannot open data.txt (attempt 3 of 5, waited 1.5 s)
//     3

    .text
    .globl  _die
    .p2align 2
_die:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     x19, x0                         // fmt
    add     x20, sp, #32                    // va_start: ap = sp on entry

    adrp    x0, prefix@PAGE
    add     x0, x0, prefix@PAGEOFF
    adrp    x1, ___stderrp@GOTPAGE
    ldr     x1, [x1, ___stderrp@GOTPAGEOFF]
    ldr     x1, [x1]
    bl      _fputs                          // fputs("fatal: ", stderr)

    adrp    x0, ___stderrp@GOTPAGE
    ldr     x0, [x0, ___stderrp@GOTPAGEOFF]
    ldr     x0, [x0]
    mov     x1, x19
    mov     x2, x20
    bl      _vfprintf                       // vfprintf(stderr, fmt, ap)

    mov     w0, #'\n'
    adrp    x1, ___stderrp@GOTPAGE
    ldr     x1, [x1, ___stderrp@GOTPAGEOFF]
    ldr     x1, [x1]
    bl      _fputc

    mov     w0, #3
    bl      _exit                           // never returns

    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #32                     // four slots
    adrp    x9, fname@PAGE
    add     x9, x9, fname@PAGEOFF
    mov     x10, #3
    stp     x9, x10, [sp]                   // %s, %d
    mov     x9, #5
    str     x9, [sp, #16]                   // %d
    fmov    d0, #1.5
    str     d0, [sp, #24]                   // %.1f
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    bl      _die
    // not reached
    add     sp, sp, #32
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
prefix: .asciz  "fatal: "
fmt:    .asciz  "cannot open %s (attempt %d of %d, waited %.1f s)"
fname:  .asciz  "data.txt"
