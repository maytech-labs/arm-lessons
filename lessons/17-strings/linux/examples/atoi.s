// atoi.s - text to number, with a sign and with validation.
//
// libc's atol("12x") quietly returns 12, and atol("abc") returns 0, so you
// cannot tell a bad input from a real 0. Our parse_long says whether the
// whole string was a valid number.
//
// C version:
//     int parse_long(const char *s, long *out) {   // 1 = ok, 0 = invalid
//         int negative = 0;
//         if (*s == '-') { negative = 1; s++; }
//         else if (*s == '+') { s++; }
//         if (*s < '0' || *s > '9') return 0;      // need at least one digit
//         long n = 0;
//         for (; *s != '\0'; s++) {
//             if (*s < '0' || *s > '9') return 0;  // junk after the digits
//             n = n * 10 + (*s - '0');
//         }
//         *out = negative ? -n : n;
//         return 1;
//     }
// (Numbers too big for a long are not detected; that is exercise 17.8.)
//
// Build: make atoi
// Run:   ./atoi
// Expected output:
//     "123": 123 (atol says 123)
//     "-45": -45 (atol says -45)
//     "+7": 7 (atol says 7)
//     "0": 0 (atol says 0)
//     "": invalid (atol says 0)
//     "-": invalid (atol says 0)
//     "12x": invalid (atol says 12)
//     " 5": invalid (atol says 5)

    .section .rodata
fmt_ok:
    .asciz  "\"%s\": %ld (atol says %ld)\n"
fmt_bad:
    .asciz  "\"%s\": invalid (atol says %ld)\n"
in1:    .asciz  "123"
in2:    .asciz  "-45"
in3:    .asciz  "+7"
in4:    .asciz  "0"
in5:    .asciz  ""
in6:    .asciz  "-"
in7:    .asciz  "12x"
in8:    .asciz  " 5"

    .data                           // a table of POINTERS goes in .data, not
    .p2align 3                      // .rodata: the addresses are only known
inputs:                             // once the program is loaded (lesson 20)
    .quad   in1, in2, in3, in4, in5, in6, in7, in8
inputs_end:

    .text
    .p2align 2
// int parse_long(const char *s, long *out)
parse_long:
    mov     x2, #0                  // n
    mov     w3, #0                  // negative
    mov     x6, #10
    ldrb    w4, [x0]
    cmp     w4, #'-'
    b.ne    parse_plus
    mov     w3, #1
    add     x0, x0, #1
    b       parse_first
parse_plus:
    cmp     w4, #'+'
    b.ne    parse_first
    add     x0, x0, #1
parse_first:
    ldrb    w4, [x0]                // the first character must be a digit
    sub     w5, w4, #'0'
    cmp     w5, #9                  // unsigned: anything below '0' wraps high
    b.hi    parse_fail              // ('\0' too: empty string or lone sign)
parse_loop:
    ldrb    w4, [x0], #1
    cbz     w4, parse_end
    sub     w5, w4, #'0'
    cmp     w5, #9
    b.hi    parse_fail
    madd    x2, x2, x6, x5          // n = n * 10 + digit
    b       parse_loop
parse_end:
    cbz     w3, parse_store
    neg     x2, x2
parse_store:
    str     x2, [x1]                // *out = n
    mov     w0, #1
    ret
parse_fail:
    mov     w0, #0
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-48]!   // frame: 16 record + 16 regs + 16 for "long n"
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]          // [sp, #40] is our local variable n

    adrp    x19, inputs
    add     x19, x19, :lo12:inputs
    adrp    x20, inputs_end
    add     x20, x20, :lo12:inputs_end
loop:
    cmp     x19, x20
    b.hs    done
    ldr     x21, [x19], #8          // s = next input
    mov     x0, x21
    add     x1, sp, #40             // &n
    bl      parse_long
    cbz     w0, bad

    mov     x0, x21
    bl      atol
    mov     x3, x0                  // atol's answer
    ldr     x2, [sp, #40]           // ours
    mov     x1, x21
    adrp    x0, fmt_ok
    add     x0, x0, :lo12:fmt_ok
    bl      printf
    b       loop
bad:
    mov     x0, x21
    bl      atol
    mov     x2, x0
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
