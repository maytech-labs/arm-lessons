// ex4.s - Exercise 19.4: the earliest date in an array of small structs (macOS).
//
// C:      struct date { short year; char month; char day; };   // 4 bytes
//         Compare dates by building year << 16 | month << 8 | day.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   earliest: 1969-07-20

    .global _main

    .equ DATE_YEAR, 0
    .equ DATE_MONTH, 2
    .equ DATE_DAY, 3
    .equ DATE_SIZE, 4

    .data
    .p2align 2
dates:
    .hword 2026
    .byte 10, 27
    .hword 1969
    .byte 7, 20
    .hword 1969
    .byte 11, 19
    .hword 1991
    .byte 8, 25
    .equ COUNT, (. - dates) / DATE_SIZE

    .section __TEXT,__const
fmt:    .asciz "earliest: %04d-%02d-%02d\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, dates@PAGE
    add x9, x9, dates@PAGEOFF
    mov x10, #COUNT
    mov w11, #-1                // best key so far: the largest unsigned value
    mov x12, x9                 // best pointer
loop:
    ldrh w13, [x9, #DATE_YEAR]
    ldrb w14, [x9, #DATE_MONTH]
    ldrb w15, [x9, #DATE_DAY]
    lsl w16, w13, #16
    orr w16, w16, w14, lsl #8
    orr w16, w16, w15           // key = year << 16 | month << 8 | day
    cmp w16, w11
    csel w11, w16, w11, lo      // earlier (unsigned compare)?
    csel x12, x9, x12, lo
    add x9, x9, #DATE_SIZE
    subs x10, x10, #1
    b.ne loop

    ldrh w1, [x12, #DATE_YEAR]
    ldrb w2, [x12, #DATE_MONTH]
    ldrb w3, [x12, #DATE_DAY]
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
