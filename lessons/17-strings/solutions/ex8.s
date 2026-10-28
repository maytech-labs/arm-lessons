// ex8.s - Exercise 17.8: parse_long that rejects numbers too big for a long.
//
// The digits are collected as an unsigned magnitude. Before each
// "n = n * 10 + d", check that the result will not pass the limit:
//     limit = negative ? 9223372036854775808 : 9223372036854775807
//     if (n > (limit - d) / 10) return 0;   // n * 10 + d would be > limit
//
// Build: make ex8
// Run:   ./ex8
// Expected output:
//     "9223372036854775807": 9223372036854775807
//     "9223372036854775808": invalid
//     "-9223372036854775808": -9223372036854775808
//     "-9223372036854775809": invalid
//     "99999999999999999999": invalid
//     "-17": -17
//     "12a": invalid

    .section .rodata
fmt_ok:
    .asciz  "\"%s\": %ld\n"
fmt_bad:
    .asciz  "\"%s\": invalid\n"
in1:    .asciz  "9223372036854775807"
in2:    .asciz  "9223372036854775808"
in3:    .asciz  "-9223372036854775808"
in4:    .asciz  "-9223372036854775809"
in5:    .asciz  "99999999999999999999"
in6:    .asciz  "-17"
in7:    .asciz  "12a"

    .data
    .p2align 3
inputs:
    .quad   in1, in2, in3, in4, in5, in6, in7
inputs_end:

    .text
    .p2align 2
// int parse_long(const char *s, long *out)
parse_long:
    mov     x2, #0                  // n (unsigned magnitude)
    mov     w3, #0                  // negative
    mov     x6, #10
    mov     x7, #0x7fffffffffffffff // limit = LONG_MAX
    ldrb    w4, [x0]
    cmp     w4, #'-'
    b.ne    parse_plus
    mov     w3, #1
    add     x7, x7, #1              // limit = LONG_MAX + 1 for negatives
    add     x0, x0, #1
    b       parse_first
parse_plus:
    cmp     w4, #'+'
    b.ne    parse_first
    add     x0, x0, #1
parse_first:
    ldrb    w4, [x0]
    sub     w5, w4, #'0'
    cmp     w5, #9
    b.hi    parse_fail
parse_loop:
    ldrb    w4, [x0], #1
    cbz     w4, parse_end
    sub     w5, w4, #'0'
    cmp     w5, #9
    b.hi    parse_fail
    sub     x8, x7, x5              // (limit - d)
    udiv    x8, x8, x6              //            / 10
    cmp     x2, x8
    b.hi    parse_fail              // n > (limit - d) / 10: too big
    madd    x2, x2, x6, x5
    b       parse_loop
parse_end:
    cbz     w3, parse_store
    neg     x2, x2                  // 2^63 negates to itself = LONG_MIN
parse_store:
    str     x2, [x1]
    mov     w0, #1
    ret
parse_fail:
    mov     w0, #0
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]          // [sp, #40] = long n
    adrp    x19, inputs
    add     x19, x19, :lo12:inputs
    adrp    x20, inputs_end
    add     x20, x20, :lo12:inputs_end
loop:
    cmp     x19, x20
    b.hs    done
    ldr     x21, [x19], #8
    mov     x0, x21
    add     x1, sp, #40
    bl      parse_long
    cbz     w0, bad
    ldr     x2, [sp, #40]
    mov     x1, x21
    adrp    x0, fmt_ok
    add     x0, x0, :lo12:fmt_ok
    bl      printf
    b       loop
bad:
    mov     x1, x21
    adrp    x0, fmt_bad
    add     x0, x0, :lo12:fmt_bad
    bl      printf
    b       loop
done:
    mov     w0, #0
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
