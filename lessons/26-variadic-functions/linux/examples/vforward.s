// vforward.s - forwarding "..." to vfprintf by building a va_list by hand.
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
// Because the format may contain %f, logmsg must save the FP argument
// registers q0-q7 as well as x1-x7, and fill in all five va_list fields.
//
// Build and run (the output goes to stderr):
//     make vforward
//     ./vforward
// Expected output:
//     [log] 3 apples cost 1.25 dollars (cheap)
//     [log] progress: 37.5% of 80, then 0.667

    .equ VA_STACK,    0
    .equ VA_GR_TOP,   8
    .equ VA_VR_TOP,  16
    .equ VA_GR_OFFS, 24
    .equ VA_VR_OFFS, 28

// Frame of logmsg (256 bytes):
//     sp+0    x29, x30
//     sp+16   x19, (padding)
//     sp+32   va_list ap              (32 bytes)
//     sp+64   x1 .. x7                (GR save area, 56 bytes, ends at sp+120)
//     sp+120  padding
//     sp+128  q0 .. q7                (VR save area, 8 * 16 = 128 bytes, ends at sp+256)
//     sp+256  = sp on entry
    .equ AP,        32
    .equ GR_SAVE,   64
    .equ GR_TOP,   120
    .equ VR_SAVE,  128
    .equ VR_TOP,   256
    .equ FRAME,    256

    .text
    .global logmsg
    .p2align 2
logmsg:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0                         // keep fmt across the fputs call

    // Save every register that might hold a variadic argument.
    stp     x1, x2, [sp, #GR_SAVE]
    stp     x3, x4, [sp, #GR_SAVE + 16]
    stp     x5, x6, [sp, #GR_SAVE + 32]
    str     x7, [sp, #GR_SAVE + 48]
    stp     q0, q1, [sp, #VR_SAVE]          // q registers are 16 bytes each
    stp     q2, q3, [sp, #VR_SAVE + 32]
    stp     q4, q5, [sp, #VR_SAVE + 64]
    stp     q6, q7, [sp, #VR_SAVE + 96]

    // va_start(ap, fmt): one named GP argument, no named FP arguments.
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]
    add     x9, sp, #GR_TOP
    str     x9, [sp, #AP + VA_GR_TOP]
    add     x9, sp, #VR_TOP
    str     x9, [sp, #AP + VA_VR_TOP]
    mov     w9, #-56                        // -(8 - 1) * 8
    str     w9, [sp, #AP + VA_GR_OFFS]
    mov     w9, #-128                       // -(8 - 0) * 16
    str     w9, [sp, #AP + VA_VR_OFFS]

    // fputs("[log] ", stderr)
    adrp    x0, prefix
    add     x0, x0, :lo12:prefix
    adrp    x1, :got:stderr
    ldr     x1, [x1, :got_lo12:stderr]      // x1 = &stderr
    ldr     x1, [x1]                        // x1 = stderr (a FILE *)
    bl      fputs

    // vfprintf(stderr, fmt, ap). va_list is a 32-byte struct, and a struct
    // bigger than 16 bytes is passed by reference: x2 = its address.
    adrp    x0, :got:stderr
    ldr     x0, [x0, :got_lo12:stderr]
    ldr     x0, [x0]
    mov     x1, x19
    add     x2, sp, #AP
    bl      vfprintf                        // x0 = characters printed: our result

    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #FRAME
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, fmt1
    add     x0, x0, :lo12:fmt1
    mov     w1, #3                          // %d   -> x1
    fmov    d0, #1.25                       // %.2f -> d0
    adrp    x2, cheap
    add     x2, x2, :lo12:cheap             // %s   -> x2 (the next GP register)
    bl      logmsg

    adrp    x0, fmt2
    add     x0, x0, :lo12:fmt2
    adrp    x1, progress
    add     x1, x1, :lo12:progress          // %s   -> x1
    adrp    x9, d_37_5                      // 37.5 is too big for an fmov immediate
    ldr     d0, [x9, :lo12:d_37_5]          // %.1f -> d0
    mov     w2, #80                         // %d   -> x2
    fmov    d1, #2.0
    fmov    d2, #3.0
    fdiv    d1, d1, d2                      // %.3f -> d1
    bl      logmsg

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
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
    .p2align 3
d_37_5:
    .double 37.5
