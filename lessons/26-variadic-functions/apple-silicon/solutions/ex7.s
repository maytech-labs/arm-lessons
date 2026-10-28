// ex7.s - exercise 26.7 (macOS): double average(int n, ...) of n doubles.
// On macOS doubles in "..." are 8-byte stack slots like everything else,
// so va_arg(ap, double) is `ldr dN, [ap], #8`. No register save area.
//
// Build and run:
//     make ex7
//     ./ex7
// Expected output:
//     average of 1.5 2.5 3.5 4.5 = 3.000000
//     average of 1..10 = 5.500000
//     average of nothing = 0.000000

    .text
    .globl  _average
    .p2align 2
_average:                                   // a leaf: no frame
    movi    d0, #0
    cbz     w0, 2f
    mov     x9, sp                          // va_start
    movi    d16, #0
    mov     w10, w0
1:
    cbz     w10, 3f
    ldr     d17, [x9], #8                   // va_arg(ap, double)
    fadd    d16, d16, d17
    sub     w10, w10, #1
    b       1b
3:
    scvtf   d17, w0
    fdiv    d0, d16, d17
2:
    ret

// print_double: printf(x0, d0). The double is printf's variadic argument,
// so it goes in the stack slot, not in d0.
    .p2align 2
print_double:
    sub     sp, sp, #32
    stp     x29, x30, [sp, #16]
    add     x29, sp, #16
    str     d0, [sp]
    bl      _printf
    ldp     x29, x30, [sp, #16]
    add     sp, sp, #32
    ret

    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    sub     sp, sp, #32
    fmov    d16, #1.5
    fmov    d17, #2.5
    stp     d16, d17, [sp]
    fmov    d16, #3.5
    fmov    d17, #4.5
    stp     d16, d17, [sp, #16]
    mov     w0, #4
    bl      _average
    add     sp, sp, #32
    adrp    x0, f1@PAGE
    add     x0, x0, f1@PAGEOFF
    bl      print_double

    // Ten doubles 1.0 .. 10.0: ten slots, 80 bytes.
    sub     sp, sp, #80
    fmov    d16, #1.0                       // d16 = next value
    fmov    d17, #1.0                       // d17 = step
    mov     x9, sp
    mov     w10, #10
1:
    str     d16, [x9], #8
    fadd    d16, d16, d17
    subs    w10, w10, #1
    b.ne    1b
    mov     w0, #10
    bl      _average
    add     sp, sp, #80
    adrp    x0, f2@PAGE
    add     x0, x0, f2@PAGEOFF
    bl      print_double

    mov     w0, #0
    bl      _average
    adrp    x0, f3@PAGE
    add     x0, x0, f3@PAGEOFF
    bl      print_double

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
f1: .asciz  "average of 1.5 2.5 3.5 4.5 = %f\n"
f2: .asciz  "average of 1..10 = %f\n"
f3: .asciz  "average of nothing = %f\n"
