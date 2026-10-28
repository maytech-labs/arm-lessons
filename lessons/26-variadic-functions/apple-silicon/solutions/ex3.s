// ex3.s - exercise 26.3 (macOS): int max_of(int n, ...) returns the largest
// of n ints. On macOS the variadic ints are 8-byte stack slots from sp on entry.
//
// Build and run:
//     make ex3
//     ./ex3
// Expected output:
//     max_of(3, 4, 9, 2) = 9
//     max_of(1, -5) = -5
//     max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5) = 9
//     max_of(5, -10, -20, -3, -40, -50) = -3

    .text
    .globl  _max_of
    .p2align 2
_max_of:                                    // a leaf: no frame needed
    mov     x9, sp                          // va_start: ap = first slot
    mov     w11, #0x80000000                // best = INT_MIN
1:
    cbz     w0, 2f
    ldr     w10, [x9], #8                   // va_arg(ap, int)
    cmp     w10, w11
    csel    w11, w10, w11, gt
    sub     w0, w0, #1
    b       1b
2:
    mov     w0, w11
    ret

// print_result: printf(fmt, w1). printf's variadic argument goes on the stack.
    .p2align 2
// The frame record sits above the argument slot, so the slot is at [sp].
print_result:
    sub     sp, sp, #32
    stp     x29, x30, [sp, #16]
    add     x29, sp, #16
    sxtw    x1, w1
    str     x1, [sp]                        // the one variadic slot
    bl      _printf
    ldp     x29, x30, [sp, #16]
    add     sp, sp, #32
    ret

    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // max_of(3, 4, 9, 2)
    sub     sp, sp, #32
    mov     x9, #4
    mov     x10, #9
    stp     x9, x10, [sp]
    mov     x9, #2
    str     x9, [sp, #16]
    mov     w0, #3
    bl      _max_of
    add     sp, sp, #32
    mov     w1, w0
    adrp    x0, f1@PAGE
    add     x0, x0, f1@PAGEOFF
    bl      print_result

    // max_of(1, -5)
    sub     sp, sp, #16
    mov     x9, #-5
    str     x9, [sp]
    mov     w0, #1
    bl      _max_of
    add     sp, sp, #16
    mov     w1, w0
    adrp    x0, f2@PAGE
    add     x0, x0, f2@PAGEOFF
    bl      print_result

    // max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5): nine slots, 80 bytes
    sub     sp, sp, #80
    mov     x9, #3
    mov     x10, #1
    stp     x9, x10, [sp]
    mov     x9, #4
    mov     x10, #1
    stp     x9, x10, [sp, #16]
    mov     x9, #5
    mov     x10, #9
    stp     x9, x10, [sp, #32]
    mov     x9, #2
    mov     x10, #6
    stp     x9, x10, [sp, #48]
    mov     x9, #5
    str     x9, [sp, #64]
    mov     w0, #9
    bl      _max_of
    add     sp, sp, #80
    mov     w1, w0
    adrp    x0, f3@PAGE
    add     x0, x0, f3@PAGEOFF
    bl      print_result

    // max_of(5, -10, -20, -3, -40, -50)
    sub     sp, sp, #48
    mov     x9, #-10
    mov     x10, #-20
    stp     x9, x10, [sp]
    mov     x9, #-3
    mov     x10, #-40
    stp     x9, x10, [sp, #16]
    mov     x9, #-50
    str     x9, [sp, #32]
    mov     w0, #5
    bl      _max_of
    add     sp, sp, #48
    mov     w1, w0
    adrp    x0, f4@PAGE
    add     x0, x0, f4@PAGEOFF
    bl      print_result

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
f1: .asciz  "max_of(3, 4, 9, 2) = %d\n"
f2: .asciz  "max_of(1, -5) = %d\n"
f3: .asciz  "max_of(9, 3, 1, 4, 1, 5, 9, 2, 6, 5) = %d\n"
f4: .asciz  "max_of(5, -10, -20, -3, -40, -50) = %d\n"
