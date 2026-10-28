// itoa.s - convert a signed long to text in any base from 2 to 36 (macOS).
//
// C version:
//     char *my_itoa(long value, char *buf, int base) {
//         char *p = buf;
//         unsigned long u = value;
//         if (value < 0) { *p++ = '-'; u = -u; }   // -u works even for LONG_MIN
//         char *digits = p;
//         do {                                     // do-while: 0 gives "0"
//             int d = u % base;
//             *p++ = d < 10 ? '0' + d : 'a' + d - 10;
//             u /= base;
//         } while (u != 0);
//         *p = '\0';
//         reverse the characters from digits to p - 1;  // they came out backwards
//         return buf;
//     }
//
// Build: make itoa
// Run:   ./itoa
// Expected output:
//     0 in base 10: 0
//     12345 in base 10: 12345
//     -42 in base 10: -42
//     255 in base 16: ff
//     255 in base 2: 11111111
//     -255 in base 16: -ff
//     35 in base 36: z
//     9223372036854775807 in base 10: 9223372036854775807
//     -9223372036854775808 in base 10: -9223372036854775808
//     -9223372036854775808 in base 16: -8000000000000000

    .section __TEXT,__const
fmt:
    .asciz  "%ld in base %d: %s\n"      // printf's %ld is the reference
tests:                                  // pairs of (value, base)
    .quad   0, 10
    .quad   12345, 10
    .quad   -42, 10
    .quad   255, 16
    .quad   255, 2
    .quad   -255, 16
    .quad   35, 36
    .quad   0x7fffffffffffffff, 10      // LONG_MAX
    .quad   0x8000000000000000, 10      // LONG_MIN
    .quad   0x8000000000000000, 16
tests_end:

    .bss
buf:
    .space  72                      // 64 binary digits + '-' + '\0' fit easily

    .text
    .p2align 2
// char *my_itoa(long value, char *buf, int base)
my_itoa:
    mov     x3, x1                  // p = buf
    mov     x4, x0                  // u = value
    mov     w5, w2                  // x5 = base (writing w5 zeroes the top)
    tbz     x0, #63, itoa_digits    // sign bit clear: not negative
    mov     w6, #'-'
    strb    w6, [x3], #1            // *p++ = '-'
    neg     x4, x0                  // u = -value
itoa_digits:
    mov     x8, x3                  // digits = p
itoa_loop:
    udiv    x6, x4, x5              // q = u / base
    msub    x7, x6, x5, x4          // d = u - q * base
    cmp     x7, #10
    b.lo    itoa_decimal
    add     x7, x7, #('a' - 10)     // 10 -> 'a', 11 -> 'b', ...
    b       itoa_store
itoa_decimal:
    add     x7, x7, #'0'
itoa_store:
    strb    w7, [x3], #1            // *p++ = digit
    mov     x4, x6                  // u = q
    cbnz    x4, itoa_loop
    strb    wzr, [x3]               // *p = '\0'
    sub     x3, x3, #1              // reverse digits .. p - 1
itoa_rev:
    cmp     x8, x3
    b.hs    itoa_done
    ldrb    w6, [x8]
    ldrb    w7, [x3]
    strb    w7, [x8], #1
    strb    w6, [x3], #-1
    b       itoa_rev
itoa_done:
    mov     x0, x1                  // return buf
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    adrp    x19, tests@PAGE         // x19 = current test
    add     x19, x19, tests@PAGEOFF
    adrp    x20, tests_end@PAGE
    add     x20, x20, tests_end@PAGEOFF
    adrp    x21, buf@PAGE
    add     x21, x21, buf@PAGEOFF
loop:
    cmp     x19, x20
    b.hs    done
    ldp     x22, x2, [x19], #16     // x22 = value, x2 = base; next pair
    mov     x0, x22
    mov     x1, x21
    bl      my_itoa                 // fills buf (x2 already holds base)
    mov     x3, x0                  // %s = buf
    ldr     x2, [x19, #-8]          // %d = base (x2 was destroyed by the call)
    mov     x1, x22                 // %ld = value
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    b       loop
done:
    mov     w0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
