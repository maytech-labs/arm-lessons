// mathlib.s - a tiny library, linked into app (see app.s). Has no main (macOS).

    .global square              // exported: other files may call these
    .global cube
    .global mathlib_calls

    .data
    .p2align 3
mathlib_calls:
    .quad 0

    .text
    .p2align 2

// long square(long x)
square:
    adrp x9, mathlib_calls@PAGE
    add x9, x9, mathlib_calls@PAGEOFF
    ldr x10, [x9]
    add x10, x10, #1
    str x10, [x9]               // mathlib_calls++
    mul x0, x0, x0
    ret

// long cube(long x)
cube:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov x1, x0
    mov x2, x0
    bl mul3
    adrp x9, mathlib_calls@PAGE
    add x9, x9, mathlib_calls@PAGEOFF
    ldr x10, [x9]
    add x10, x10, #1
    str x10, [x9]
    ldp x29, x30, [sp], #16
    ret

// long mul3(long a, long b, long c): not .global, so private to this file
mul3:
    mul x0, x0, x1
    mul x0, x0, x2
    ret
