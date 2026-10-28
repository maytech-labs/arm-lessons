// ex8.s - my_atof: parse "[+|-]digits[.digits]" into a double by hand (lesson 23, exercise 23.8)
//
// Build: make ex8
// Run:   ./ex8
// Expected output:
//   "3.25" -> 3.250000
//   "-0.5" -> -0.500000
//   "42" -> 42.000000
//   "+7.75" -> 7.750000
//   "12.125" -> 12.125000

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    adrp x19, tests
    add x19, x19, :lo12:tests   // x19 = &tests[0] (array of char *)
main_loop:
    ldr x20, [x19], #8          // s = *tests++
    cbz x20, main_done          // NULL ends the list
    mov x0, x20
    bl my_atof                  // d0 = my_atof(s)
    mov x1, x20                 // printf(fmt, s, value)
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf
    b main_loop
main_done:
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// double my_atof(const char *s)         (leaf)
//     sign = 1; if (*s == '-') { sign = -1; s++; } else if (*s == '+') s++;
//     value = 0; while (isdigit(*s)) value = value * 10 + (*s++ - '0');
//     scale = 1; if (*s == '.') { s++; while (isdigit(*s)) {
//         value = value * 10 + (*s++ - '0'); scale *= 10; } }
//     return sign * value / scale;
my_atof:
    fmov d0, xzr                // value = 0.0
    fmov d1, #1.0               // scale = 1.0
    fmov d2, #10.0              // the constant 10.0
    fmov d4, #1.0               // sign = 1.0
    ldrb w1, [x0]
    cmp w1, #'-'
    b.ne atof_plus
    fmov d4, #-1.0
    add x0, x0, #1
    b atof_int
atof_plus:
    cmp w1, #'+'
    b.ne atof_int
    add x0, x0, #1
atof_int:
    ldrb w1, [x0]
    sub w1, w1, #'0'            // digit = c - '0'
    cmp w1, #9
    b.hi atof_point             // unsigned > 9: not a digit
    scvtf d3, w1                // (double)digit
    fmadd d0, d0, d2, d3        // value = value * 10 + digit
    add x0, x0, #1
    b atof_int
atof_point:
    ldrb w1, [x0]
    cmp w1, #'.'
    b.ne atof_done
    add x0, x0, #1
atof_frac:
    ldrb w1, [x0]
    sub w1, w1, #'0'
    cmp w1, #9
    b.hi atof_done
    scvtf d3, w1
    fmadd d0, d0, d2, d3        // value = value * 10 + digit
    fmul d1, d1, d2             // scale *= 10
    add x0, x0, #1
    b atof_frac
atof_done:
    fdiv d0, d0, d1             // value / scale
    fmul d0, d0, d4             // * sign
    ret

    .section .rodata
s1: .asciz "3.25"
s2: .asciz "-0.5"
s3: .asciz "42"
s4: .asciz "+7.75"
s5: .asciz "12.125"
fmt: .asciz "\"%s\" -> %f\n"

    .data
    .p2align 3
tests:
    .quad s1, s2, s3, s4, s5, 0
