// local_labels.s - numbered local labels: 1:, then 1b (back) or 1f (forward) (macOS).
//
// C:      count the vowels and the spaces in a string
//
// Build:  make
// Run:    ./local_labels
// Expected output:
//   "the quick brown fox": 5 vowels, 3 spaces

    .global _main

    .section __TEXT,__const
text:   .asciz "the quick brown fox"
vowels: .asciz "aeiou"
fmt:    .asciz "\"%s\": %ld vowels, %ld spaces\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, text@PAGE
    add x9, x9, text@PAGEOFF
    mov x2, #0                  // vowels
    mov x3, #0                  // spaces
1:  ldrb w10, [x9], #1          // the outer loop: label "1"
    cbz w10, 3f                 // end of string: jump FORWARD to the next "3"
    cmp w10, #' '
    cinc x3, x3, eq
    adrp x11, vowels@PAGE
    add x11, x11, vowels@PAGEOFF
2:  ldrb w12, [x11], #1         // the inner loop: label "2"
    cbz w12, 1b                 // not a vowel: back to the most recent "1"
    cmp w10, w12
    b.ne 2b                     // try the next vowel: back to the most recent "2"
    add x2, x2, #1
    b 1b
3:
    adrp x1, text@PAGE
    add x1, x1, text@PAGEOFF
    adrp x0, fmt@PAGE
    add x0, x0, fmt@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
