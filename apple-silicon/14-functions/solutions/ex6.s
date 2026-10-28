// ex6.s - Exercise 14.6: print_hex(n) prints n as 0x followed by hex digits (macOS).
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   0xdeadbeef 0x0 0xff
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    movz x0, #0xbeef
    movk x0, #0xdead, lsl #16
    bl print_hex
    mov x0, #' '
    bl print_char
    mov x0, #0
    bl print_hex
    mov x0, #' '
    bl print_char
    mov x0, #0xff
    bl print_hex
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x16, #1
    svc #0x80

// void print_hex(unsigned long n): leaf. Digits are made from the low 4 bits,
// last digit first, like print_uint, but with and/lsr instead of udiv/msub.
print_hex:
    sub sp, sp, #32
    add x5, sp, #32             // end of buffer
    mov x1, x5
print_hex_digit:
    and x6, x0, #0xf            // the lowest hex digit, 0-15
    add x7, x6, #'0'            // '0'..'9'
    add x6, x6, #'a' - 10       // 'a'..'f'
    cmp x7, #'9'
    csel x6, x7, x6, ls         // pick '0'-'9' if the digit was < 10
    strb w6, [x1, #-1]!
    lsr x0, x0, #4              // next digit
    cbnz x0, print_hex_digit
    mov w6, #'x'
    strb w6, [x1, #-1]!
    mov w6, #'0'
    strb w6, [x1, #-1]!         // "0x" in front
    mov x0, #1
    sub x2, x5, x1
    mov x16, #4
    svc #0x80
    add sp, sp, #32
    ret

// void print_char(char c)
//   in:  w0 = c
print_char:
    sub sp, sp, #16             // a 1-byte buffer, but sp moves by 16
    strb w0, [sp]
    mov x0, #1                  // write(1, &c, 1)
    mov x1, sp
    mov x2, #1
    mov x16, #4
    svc #0x80
    add sp, sp, #16
    ret
