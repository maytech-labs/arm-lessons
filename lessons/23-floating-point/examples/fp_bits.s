// fp_bits.s - show the IEEE 754 bits of some doubles and floats (lesson 23)
//
// Build: make fp_bits
// Run:   ./fp_bits
// Expected output:
//     1.000000  bits 0x3ff0000000000000  sign 0  exp 1023  frac 0x0000000000000
//    -2.500000  bits 0xc004000000000000  sign 1  exp 1024  frac 0x4000000000000
//     0.100000  bits 0x3fb999999999999a  sign 0  exp 1019  frac 0x999999999999a
//     0.000000  bits 0x0000000000000000  sign 0  exp    0  frac 0x0000000000000
//    -0.000000  bits 0x8000000000000000  sign 1  exp    0  frac 0x0000000000000
//   float 1.000000  bits 0x3f800000
//   float 0.100000  bits 0x3dcccccd

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    fmov d0, #1.0               // fits in an fmov immediate
    bl show_double
    fmov d0, #-2.5              // so does this
    bl show_double
    adrp x0, tenth              // 0.1 does not: load it from memory
    ldr d0, [x0, :lo12:tenth]
    bl show_double
    fmov d0, xzr                // 0.0: copy the bits of xzr (all zero)
    bl show_double
    fmov d0, xzr                // d0 is caller-saved: show_double may have changed it
    fneg d0, d0                 // -0.0: the bits of 0.0 with the sign bit set
    bl show_double

    fmov s0, #1.0               // float 1.0f
    bl show_float
    adrp x0, tenth_f            // float 0.1f
    ldr s0, [x0, :lo12:tenth_f]
    bl show_float

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// void show_double(double d): print d, its 64 bits, and the three fields
show_double:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    fmov x1, d0                 // x1 = the raw bits of d (no conversion)
    ubfx x2, x1, #63, #1        // sign:      bit 63
    ubfx x3, x1, #52, #11       // exponent:  bits 52-62
    ubfx x4, x1, #0, #52        // fraction:  bits 0-51
    adrp x0, dfmt               // printf(dfmt, d, bits, sign, exp, frac)
    add x0, x0, :lo12:dfmt      // d is still in d0; integers in x1-x4
    bl printf
    ldp x29, x30, [sp], #16
    ret

// void show_float(float f): print f and its 32 bits
show_float:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    fmov w1, s0                 // w1 = the raw 32 bits of f
    fcvt d0, s0                 // printf wants a double: widen f
    adrp x0, ffmt
    add x0, x0, :lo12:ffmt
    bl printf
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
    .p2align 3
tenth:
    .double 0.1
tenth_f:
    .float 0.1
dfmt:
    .asciz "%10f  bits 0x%016lx  sign %ld  exp %4ld  frac 0x%013lx\n"
ffmt:
    .asciz "float %f  bits 0x%08x\n"
