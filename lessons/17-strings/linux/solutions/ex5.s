// ex5.s - Exercise 17.5: count the words in a string.
//
// A word is a run of non-space characters.
//
// C version:
//     long word_count(const char *s) {
//         long n = 0;
//         int in_word = 0;
//         for (; *s; s++) {
//             if (*s == ' ') in_word = 0;
//             else if (!in_word) { in_word = 1; n++; }   // a word starts here
//         }
//         return n;
//     }
//
// Build: make ex5
// Run:   ./ex5
// Expected output:
//     "  hello   world  ": 2
//     "one": 1
//     "": 0
//     "a b c d": 4

    .section .rodata
fmt:
    .asciz  "\"%s\": %ld\n"
in1:    .asciz  "  hello   world  "
in2:    .asciz  "one"
in3:    .asciz  ""
in4:    .asciz  "a b c d"

    .data
    .p2align 3
inputs:
    .quad   in1, in2, in3, in4
inputs_end:

    .text
    .p2align 2
// long word_count(const char *s)
word_count:
    mov     x1, #0                  // n
    mov     w2, #0                  // in_word
wc_loop:
    ldrb    w3, [x0], #1
    cbz     w3, wc_done
    cmp     w3, #' '
    b.ne    wc_not_space
    mov     w2, #0                  // a space ends the word
    b       wc_loop
wc_not_space:
    cbnz    w2, wc_loop             // already inside a word
    mov     w2, #1                  // a new word starts
    add     x1, x1, #1
    b       wc_loop
wc_done:
    mov     x0, x1
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    adrp    x19, inputs
    add     x19, x19, :lo12:inputs
    adrp    x20, inputs_end
    add     x20, x20, :lo12:inputs_end
loop:
    cmp     x19, x20
    b.hs    done
    ldr     x21, [x19], #8
    mov     x0, x21
    bl      word_count
    mov     x2, x0
    mov     x1, x21
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    bl      printf
    b       loop
done:
    mov     w0, #0
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
