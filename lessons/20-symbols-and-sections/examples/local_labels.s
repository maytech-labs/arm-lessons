// local_labels.s - numbered local labels: 1:, then 1b (back) or 1f (forward).
//
// C:      count the vowels and the spaces in a string
//
// Build:  make
// Run:    ./local_labels
// Expected output:
//   "the quick brown fox": 5 vowels, 3 spaces

    .global main

    .section .rodata
text:   .asciz "the quick brown fox"
vowels: .asciz "aeiou"
fmt:    .asciz "\"%s\": %ld vowels, %ld spaces\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, text
    add x9, x9, :lo12:text
    mov x2, #0                  // vowels
    mov x3, #0                  // spaces
1:  ldrb w10, [x9], #1          // the outer loop: label "1"
    cbz w10, 3f                 // end of string: jump FORWARD to the next "3"
    cmp w10, #' '
    cinc x3, x3, eq
    adrp x11, vowels
    add x11, x11, :lo12:vowels
2:  ldrb w12, [x11], #1         // the inner loop: label "2"
    cbz w12, 1b                 // not a vowel: back to the most recent "1"
    cmp w10, w12
    b.ne 2b                     // try the next vowel: back to the most recent "2"
    add x2, x2, #1
    b 1b
3:
    adrp x1, text
    add x1, x1, :lo12:text
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
