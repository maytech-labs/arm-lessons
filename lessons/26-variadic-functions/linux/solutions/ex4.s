// ex4.s - exercise 26.4: myprintf from the lesson, plus %u and %b.
//
// Build and run:
//     make ex4
//     ./ex4
// Expected output:
//     u: 4294967295 0 42
//     b: 101 0 11111111 10000000000000000000000000000000
//     returned 51

    .equ VA_STACK,    0
    .equ VA_GR_TOP,   8
    .equ VA_VR_TOP,  16
    .equ VA_GR_OFFS, 24
    .equ VA_VR_OFFS, 28

// Frame of myprintf (144 bytes):
//     sp+0    x29, x30
//     sp+16   x19, x20
//     sp+32   x21, (padding)
//     sp+48   va_list ap        (32 bytes)
//     sp+80   x1 .. x7          (register save area, 56 bytes, ends at sp+136)
//     sp+136  padding
//     sp+144  = sp on entry
    .equ AP,       48
    .equ GR_SAVE,  80
    .equ GR_TOP,  136
    .equ FRAME,   144

    .text
    .global myprintf
    .p2align 2
myprintf:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]

    // Spill x1..x7 first: the first putchar would destroy them.
    stp     x1, x2, [sp, #GR_SAVE]
    stp     x3, x4, [sp, #GR_SAVE + 16]
    stp     x5, x6, [sp, #GR_SAVE + 32]
    str     x7, [sp, #GR_SAVE + 48]

    // va_start(ap, fmt)
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]
    add     x9, sp, #GR_TOP
    str     x9, [sp, #AP + VA_GR_TOP]
    str     xzr, [sp, #AP + VA_VR_TOP]      // we never read doubles
    mov     w9, #-56                        // one named GP argument: 7 left
    str     w9, [sp, #AP + VA_GR_OFFS]
    str     wzr, [sp, #AP + VA_VR_OFFS]

    mov     x19, x0                         // x19 = p, walks the format
    mov     x20, #0                         // x20 = count of characters printed

next:
    ldrb    w0, [x19], #1                   // c = *p++
    cbz     w0, finish
    cmp     w0, #'%'
    b.eq    percent
    bl      putchar                         // ordinary character
    add     x20, x20, #1
    b       next

percent:
    ldrb    w21, [x19], #1                  // the conversion letter, kept safe in w21
    cmp     w21, #'d'
    b.eq    conv_d
    cmp     w21, #'x'
    b.eq    conv_x
    cmp     w21, #'u'
    b.eq    conv_u
    cmp     w21, #'b'
    b.eq    conv_b
    cmp     w21, #'s'
    b.eq    conv_s
    cmp     w21, #'c'
    b.eq    conv_c
    cmp     w21, #'%'
    b.eq    conv_pct
    cbz     w21, conv_end                   // "...%" at the very end of fmt
    // unknown: print it unchanged
    mov     w0, #'%'
    bl      putchar
    mov     w0, w21
    bl      putchar
    add     x20, x20, #2
    b       next

conv_d:
    add     x0, sp, #AP
    bl      next_gr                         // x0 = address of the next int
    ldrsw   x0, [x0]                        // int, sign-extended to 64 bits
    bl      print_signed
    add     x20, x20, x0
    b       next

conv_x:
    add     x0, sp, #AP
    bl      next_gr
    ldr     w0, [x0]                        // unsigned int, zero-extended
    mov     x1, #16
    bl      print_unsigned
    add     x20, x20, x0
    b       next

conv_u:                                     // new: unsigned decimal
    add     x0, sp, #AP
    bl      next_gr
    ldr     w0, [x0]                        // unsigned int, zero-extended
    mov     x1, #10
    bl      print_unsigned
    add     x20, x20, x0
    b       next

conv_b:                                     // new: unsigned binary
    add     x0, sp, #AP
    bl      next_gr
    ldr     w0, [x0]
    mov     x1, #2
    bl      print_unsigned                  // 32 binary digits fit the 32-byte buffer
    add     x20, x20, x0
    b       next

conv_s:
    add     x0, sp, #AP
    bl      next_gr
    ldr     x0, [x0]                        // char *
    bl      print_str
    add     x20, x20, x0
    b       next

conv_c:
    add     x0, sp, #AP
    bl      next_gr
    ldr     w0, [x0]                        // char was promoted to int
    bl      putchar
    add     x20, x20, #1
    b       next

conv_end:
    sub     x19, x19, #1                    // point back at the NUL so the loop ends
conv_pct:
    mov     w0, #'%'
    bl      putchar
    add     x20, x20, #1
    b       next

finish:
    mov     x0, x20                         // return count
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #FRAME
    ret

// next_gr: va_arg for one 8-byte integer-class argument.
//     x0 = address of a va_list.  Returns x0 = address of the argument.
// A leaf function: no calls, so no frame is needed.
    .p2align 2
next_gr:
    ldr     w9, [x0, #VA_GR_OFFS]           // offs
    tbz     w9, #31, 1f                     // offs >= 0: take it from the stack
    add     w10, w9, #8
    str     w10, [x0, #VA_GR_OFFS]          // __gr_offs += 8
    ldr     x10, [x0, #VA_GR_TOP]
    add     x0, x10, w9, sxtw               // __gr_top + offs
    ret
1:
    ldr     x10, [x0, #VA_STACK]
    add     x11, x10, #8
    str     x11, [x0, #VA_STACK]            // __stack += 8
    mov     x0, x10
    ret

// print_unsigned: print x0 in base x1 (2..16). Returns the number of digits.
    .p2align 2
print_unsigned:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]             // buffer is sp+32 .. sp+63
    add     x19, sp, #64                    // x19 = one past the end of the buffer
    adrp    x9, digits
    add     x9, x9, :lo12:digits
1:
    udiv    x10, x0, x1                     // q = v / base
    msub    x11, x10, x1, x0                // r = v - q * base
    ldrb    w11, [x9, x11]                  // digit character
    strb    w11, [x19, #-1]!                // store backwards
    mov     x0, x10
    cbnz    x0, 1b
    add     x20, sp, #64
    sub     x20, x20, x19                   // x20 = number of digits
2:
    ldrb    w0, [x19], #1
    bl      putchar
    add     x9, sp, #64
    cmp     x19, x9
    b.lo    2b
    mov     x0, x20
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// print_signed: print the signed 64-bit value x0 in decimal. Returns the count.
    .p2align 2
print_signed:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0
    tbz     x19, #63, 1f                    // not negative: just print it
    mov     w0, #'-'
    bl      putchar
    neg     x0, x19
    mov     x1, #10
    bl      print_unsigned
    add     x0, x0, #1                      // the '-' counts too
    b       2f
1:
    mov     x0, x19
    mov     x1, #10
    bl      print_unsigned
2:
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// print_str: print the C string at x0 ("(null)" for NULL). Returns the count.
    .p2align 2
print_str:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     x19, x0
    cbnz    x19, 1f
    adrp    x19, nullstr
    add     x19, x19, :lo12:nullstr
1:
    mov     x20, #0
2:
    ldrb    w0, [x19], #1
    cbz     w0, 3f
    bl      putchar
    add     x20, x20, #1
    b       2b
3:
    mov     x0, x20
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// main: the test calls from the exercise.
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, fmt_u
    add     x0, x0, :lo12:fmt_u
    mov     w1, #-1                         // 0xffffffff as an unsigned int
    mov     w2, #0
    mov     w3, #42
    bl      myprintf

    adrp    x0, fmt_b
    add     x0, x0, :lo12:fmt_b
    mov     w1, #5
    mov     w2, #0
    mov     w3, #255
    mov     w4, #0x80000000
    bl      myprintf

    mov     w1, w0                          // what the second call returned
    adrp    x0, fmt_r
    add     x0, x0, :lo12:fmt_r
    bl      printf

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
fmt_u:
    .asciz  "u: %u %u %u\n"
fmt_b:
    .asciz  "b: %b %b %b %b\n"
fmt_r:
    .asciz  "returned %d\n"
digits:
    .ascii  "0123456789abcdef"
nullstr:
    .asciz  "(null)"
