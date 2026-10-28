// sum.s - a variadic function written by hand: int sum(int n, ...).
//
// The C version:
//     int sum(int n, ...) {
//         va_list ap;
//         va_start(ap, n);
//         int total = 0;
//         for (int i = 0; i < n; i++)
//             total += va_arg(ap, int);
//         va_end(ap);
//         return total;
//     }
//
// This file has no main. It is linked with the C test driver sum_test.c,
// which calls sum() with 0, 3, 7 and 10 extra arguments (the 10-argument call
// forces three of them onto the stack).
//
// Build and run:
//     make sum
//     ./sum
// Expected output:
//     sum(0) = 0
//     sum(3, 10, 20, 30) = 60
//     sum(7, 1..7) = 28
//     sum(10, 1..10) = 55
//     sum(4, -5, 100, -20, 1) = 76

// Layout of the AAPCS64 va_list, a 32-byte struct:
    .equ VA_STACK,    0     // void *__stack:   next argument on the stack
    .equ VA_GR_TOP,   8     // void *__gr_top:  end of the general register save area
    .equ VA_VR_TOP,  16     // void *__vr_top:  end of the FP/SIMD register save area
    .equ VA_GR_OFFS, 24     // int   __gr_offs: -(bytes of GR save area left), or >= 0
    .equ VA_VR_OFFS, 28     // int   __vr_offs: same for the FP/SIMD save area

// Frame of sum (112 bytes):
//     sp+0    x29, x30
//     sp+16   va_list ap        (32 bytes, up to sp+48)
//     sp+48   x1 .. x7          (the register save area, 56 bytes, up to sp+104)
//     sp+104  padding           (8 bytes, keeps the frame a multiple of 16)
//     sp+112  = sp on entry     = where the caller put stacked arguments
    .equ AP,       16
    .equ GR_SAVE,  48
    .equ GR_TOP,  104
    .equ FRAME,   112

    .text
    .global sum
    .p2align 2
sum:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp

    // --- Spill the unnamed register arguments -----------------------------
    // n is the only named argument, so x1..x7 may hold variadic ones.
    // Store all seven: va_arg will read them back from memory.
    stp     x1, x2, [sp, #GR_SAVE]
    stp     x3, x4, [sp, #GR_SAVE + 16]
    stp     x5, x6, [sp, #GR_SAVE + 32]
    str     x7, [sp, #GR_SAVE + 48]

    // --- va_start(ap, n) ---------------------------------------------------
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]        // __stack  = sp on entry
    add     x9, sp, #GR_TOP
    str     x9, [sp, #AP + VA_GR_TOP]       // __gr_top = end of x1..x7
    str     xzr, [sp, #AP + VA_VR_TOP]      // no FP save area: sum reads ints only
    mov     w9, #-56                        // 7 registers * 8 bytes still unread
    str     w9, [sp, #AP + VA_GR_OFFS]
    str     wzr, [sp, #AP + VA_VR_OFFS]     // 0 = "FP registers used up"

    // --- the loop ----------------------------------------------------------
    // Nothing here calls another function, so temporaries are safe.
    mov     w10, w0                         // w10 = arguments left to read
    mov     w11, #0                         // w11 = total
loop:
    cmp     w10, #0
    b.le    done

    // --- va_arg(ap, int): find the address of the next integer argument ----
    ldr     w12, [sp, #AP + VA_GR_OFFS]     // offs = ap.__gr_offs
    tbz     w12, #31, from_stack            // offs >= 0: registers used up
    add     w13, w12, #8
    str     w13, [sp, #AP + VA_GR_OFFS]     // ap.__gr_offs = offs + 8
    ldr     x14, [sp, #AP + VA_GR_TOP]
    add     x14, x14, w12, sxtw             // addr = __gr_top + offs
    b       have_addr
from_stack:
    ldr     x14, [sp, #AP + VA_STACK]       // addr = __stack
    add     x13, x14, #8
    str     x13, [sp, #AP + VA_STACK]       // __stack += 8 (one slot)
have_addr:
    ldr     w15, [x14]                      // the int itself

    add     w11, w11, w15                   // total += va_arg(ap, int)
    sub     w10, w10, #1
    b       loop

done:
    mov     w0, w11                         // return total
    ldp     x29, x30, [sp], #FRAME
    ret
