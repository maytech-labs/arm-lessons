// myprintf.s - a tiny printf written by hand for macOS:
// int myprintf(const char *fmt, ...).
//
// Supports %d (int), %x (unsigned int in hex), %c (char), %s (string) and %%.
// Any other %? is printed unchanged. Output goes through putchar, so it shares
// stdout's buffer with printf. Returns the number of characters printed.
// (The C shape of it is in the header of ../../../lessons/26-variadic-functions/examples/myprintf.s.)
//
// On macOS va_list is a plain pointer to the next 8-byte stack slot, so we
// keep it in a callee-saved register (x22) and va_arg is one post-indexed load.
//
// This file has no main. It is linked with the C driver myprintf_test.c
// (binary: myprintf) and with the assembly caller pfdemo.s (binary: pfdemo).
//
// Build and run:
//     make myprintf
//     ./myprintf
// Expected output: see the header of myprintf_test.c.

// Frame of myprintf (48 bytes):
//     sp+0    x29, x30
//     sp+16   x19, x20
//     sp+32   x21, x22
//     sp+48   = sp on entry = the first variadic argument
    .equ FRAME, 48

    .text
    .globl  _myprintf
    .p2align 2
_myprintf:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    add     x22, sp, #FRAME                 // va_start: x22 = ap
    mov     x19, x0                         // x19 = p, walks the format
    mov     x20, #0                         // x20 = count

next:
    ldrb    w0, [x19], #1
    cbz     w0, finish
    cmp     w0, #'%'
    b.eq    percent
    bl      _putchar
    add     x20, x20, #1
    b       next

percent:
    ldrb    w21, [x19], #1                  // the conversion letter
    cmp     w21, #'d'
    b.eq    conv_d
    cmp     w21, #'x'
    b.eq    conv_x
    cmp     w21, #'s'
    b.eq    conv_s
    cmp     w21, #'c'
    b.eq    conv_c
    cmp     w21, #'%'
    b.eq    conv_pct
    cbz     w21, conv_end
    mov     w0, #'%'                        // unknown: print it unchanged
    bl      _putchar
    mov     w0, w21
    bl      _putchar
    add     x20, x20, #2
    b       next

conv_d:
    ldrsw   x0, [x22], #8                   // va_arg(ap, int), sign-extended
    bl      print_signed
    add     x20, x20, x0
    b       next

conv_x:
    ldr     w0, [x22], #8                   // va_arg(ap, unsigned)
    mov     x1, #16
    bl      print_unsigned
    add     x20, x20, x0
    b       next

conv_s:
    ldr     x0, [x22], #8                   // va_arg(ap, char *)
    bl      print_str
    add     x20, x20, x0
    b       next

conv_c:
    ldr     w0, [x22], #8                   // va_arg(ap, int)
    bl      _putchar
    add     x20, x20, #1
    b       next

conv_end:
    sub     x19, x19, #1                    // back to the NUL so the loop ends
conv_pct:
    mov     w0, #'%'
    bl      _putchar
    add     x20, x20, #1
    b       next

finish:
    mov     x0, x20
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #FRAME
    ret

// print_unsigned: print x0 in base x1 (2..16). Returns the number of digits.
    .p2align 2
print_unsigned:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]             // buffer is sp+32 .. sp+63
    add     x19, sp, #64
    adrp    x9, digits@PAGE
    add     x9, x9, digits@PAGEOFF
1:
    udiv    x10, x0, x1
    msub    x11, x10, x1, x0
    ldrb    w11, [x9, x11]
    strb    w11, [x19, #-1]!
    mov     x0, x10
    cbnz    x0, 1b
    add     x20, sp, #64
    sub     x20, x20, x19
2:
    ldrb    w0, [x19], #1
    bl      _putchar
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
    tbz     x19, #63, 1f
    mov     w0, #'-'
    bl      _putchar
    neg     x0, x19
    mov     x1, #10
    bl      print_unsigned
    add     x0, x0, #1
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
    adrp    x19, nullstr@PAGE
    add     x19, x19, nullstr@PAGEOFF
1:
    mov     x20, #0
2:
    ldrb    w0, [x19], #1
    cbz     w0, 3f
    bl      _putchar
    add     x20, x20, #1
    b       2b
3:
    mov     x0, x20
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section __TEXT,__const
digits:
    .ascii  "0123456789abcdef"

    .section __TEXT,__cstring
nullstr:
    .asciz  "(null)"
