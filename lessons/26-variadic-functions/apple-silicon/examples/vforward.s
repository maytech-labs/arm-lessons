// vforward.s - forwarding "..." to vfprintf on macOS.
//
// The C version:
//     int logmsg(const char *fmt, ...) {
//         va_list ap;
//         va_start(ap, fmt);
//         fputs("[log] ", stderr);
//         int n = vfprintf(stderr, fmt, ap);
//         va_end(ap);
//         return n;
//     }
//     int main(void) {
//         logmsg("%d apples cost %.2f dollars (%s)\n", 3, 1.25, "cheap");
//         logmsg("%s: %.1f%% of %d, then %.3f\n", "progress", 37.5, 80, 2.0 / 3.0);
//         return 0;
//     }
//
// On macOS va_list is a char *: the address of the first variadic stack slot.
// There are no registers to save, and we pass that pointer itself in x2.
//
// Build and run (the output goes to stderr):
//     make vforward
//     ./vforward
// Expected output:
//     [log] 3 apples cost 1.25 dollars (cheap)
//     [log] progress: 37.5% of 80, then 0.667

    .text
    .globl  _logmsg
    .p2align 2
_logmsg:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     x19, x0                         // fmt
    add     x20, sp, #32                    // va_start: x20 = ap = sp on entry

    adrp    x0, prefix@PAGE
    add     x0, x0, prefix@PAGEOFF
    adrp    x1, ___stderrp@GOTPAGE
    ldr     x1, [x1, ___stderrp@GOTPAGEOFF] // x1 = &__stderrp
    ldr     x1, [x1]                        // x1 = stderr
    bl      _fputs

    adrp    x0, ___stderrp@GOTPAGE
    ldr     x0, [x0, ___stderrp@GOTPAGEOFF]
    ldr     x0, [x0]
    mov     x1, x19
    mov     x2, x20                         // va_list is a pointer: pass it as is
    bl      _vfprintf                       // vfprintf is not variadic: x0-x2

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    sub     sp, sp, #32                     // three slots, rounded up
    mov     x9, #3
    str     x9, [sp]                        // %d
    fmov    d0, #1.25
    str     d0, [sp, #8]                    // %.2f
    adrp    x9, cheap@PAGE
    add     x9, x9, cheap@PAGEOFF
    str     x9, [sp, #16]                   // %s
    adrp    x0, fmt1@PAGE
    add     x0, x0, fmt1@PAGEOFF
    bl      _logmsg
    add     sp, sp, #32

    sub     sp, sp, #32                     // four slots
    adrp    x9, progress@PAGE
    add     x9, x9, progress@PAGEOFF
    str     x9, [sp]                        // %s
    adrp    x9, d_37_5@PAGE
    ldr     d0, [x9, d_37_5@PAGEOFF]
    str     d0, [sp, #8]                    // %.1f
    mov     x9, #80
    str     x9, [sp, #16]                   // %d
    fmov    d1, #2.0
    fmov    d2, #3.0
    fdiv    d1, d1, d2
    str     d1, [sp, #24]                   // %.3f
    adrp    x0, fmt2@PAGE
    add     x0, x0, fmt2@PAGEOFF
    bl      _logmsg
    add     sp, sp, #32

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
prefix:
    .asciz  "[log] "
fmt1:
    .asciz  "%d apples cost %.2f dollars (%s)\n"
fmt2:
    .asciz  "%s: %.1f%% of %d, then %.3f\n"
cheap:
    .asciz  "cheap"
progress:
    .asciz  "progress"

    .section __TEXT,__const
    .p2align 3
d_37_5:
    .double 37.5
