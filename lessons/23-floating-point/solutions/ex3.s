// ex3.s - Fahrenheit to Celsius table, 0 to 100 in steps of 20 (lesson 23, exercise 23.3)
//
// Build: make ex3
// Run:   ./ex3
// Expected output:
//     0 F =  -17.8 C
//    20 F =   -6.7 C
//    40 F =    4.4 C
//    60 F =   15.6 C
//    80 F =   26.7 C
//   100 F =   37.8 C

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov x19, #0                 // for (long f = 0; f <= 100; f += 20)
loop:
    cmp x19, #100
    b.gt done
    scvtf d0, x19               // (double)f
    adrp x0, k32                // 32.0 is NOT an fmov immediate (too big):
    ldr d1, [x0, :lo12:k32]     //   load it from memory
    fsub d0, d0, d1             // f - 32
    fmov d1, #5.0
    fmul d0, d0, d1             // * 5
    fmov d1, #9.0
    fdiv d0, d0, d1             // / 9   (all in double: no truncation)
    mov x1, x19                 // printf(fmt, f, c): f in x1, c in d0
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    add x19, x19, #20
    b loop
done:
    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
    .p2align 3
k32: .double 32.0
fmt: .asciz "%3ld F = %6.1f C\n"
