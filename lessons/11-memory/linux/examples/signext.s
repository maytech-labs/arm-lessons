// signext.s - the same byte, 0xfb, loaded unsigned (251) and signed (-5).
//
// Build:  make
// Run:    ./signext; echo $?
// Expect: exit status 1 (the signed load gave a negative number).
//         Change ldrsb to ldrb, rebuild, and it exits 2 instead.

    .global _start

    .data
small:
    .byte -5                    // stored as the bit pattern 0xfb

    .text
    .p2align 2

_start:
    adrp x0, small
    add x0, x0, :lo12:small
    ldrsb x1, [x0]              // x1 = 0xfffffffffffffffb = -5  (signed load)
    ldrb w2, [x0]               // x2 = 0x00000000000000fb = 251 (unsigned load)

    cmp x1, #0                  // is the signed load negative?
    b.lt negative
    mov x0, #2                  // no: exit 2
    b done
negative:
    mov x0, #1                  // yes: exit 1
done:
    mov x8, #93                 // 93 = exit
    svc #0
