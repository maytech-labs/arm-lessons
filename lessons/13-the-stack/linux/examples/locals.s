// locals.s - local variables in a stack frame.
//
// C:      long w = 6, h = 7;
//         long area = w * h;
//         long perimeter = 2 * (w + h);
//         return area - perimeter;           // 42 - 26 = 16
//
// Build:  make
// Run:    ./locals; echo $?
// Exit status (echo $?): 16
//
// Frame layout (offsets from sp):
//     [sp, #0]   w
//     [sp, #8]   h
//     [sp, #16]  area
//     [sp, #24]  perimeter

    .global _start
    .text
    .p2align 2

_start:
    sub sp, sp, #32             // make room for four longs (32 bytes, a multiple of 16)

    mov x0, #6
    str x0, [sp, #0]            // w = 6
    mov x0, #7
    str x0, [sp, #8]            // h = 7

    ldp x1, x2, [sp, #0]        // x1 = w, x2 = h (two neighbours in one load)
    mul x3, x1, x2
    str x3, [sp, #16]           // area = w * h

    add x3, x1, x2
    lsl x3, x3, #1
    str x3, [sp, #24]           // perimeter = 2 * (w + h)

    ldr x0, [sp, #16]
    ldr x1, [sp, #24]
    sub x0, x0, x1              // area - perimeter

    add sp, sp, #32             // give the space back
    mov x8, #93
    svc #0
