// ex4.s - Exercise 17.4: is a string a palindrome?
//
// C version:
//     int is_palindrome(const char *s) {
//         const char *i = s, *j = s + strlen(s) - 1;
//         while (i < j) if (*i++ != *j--) return 0;
//         return 1;
//     }
//
// Build: make ex4
// Run:   ./ex4
// Expected output:
//     "racecar": 1
//     "abba": 1
//     "abca": 0
//     "a": 1
//     "": 1

    .section .rodata
fmt:
    .asciz  "\"%s\": %d\n"
in1:    .asciz  "racecar"
in2:    .asciz  "abba"
in3:    .asciz  "abca"
in4:    .asciz  "a"
in5:    .asciz  ""

    .data
    .p2align 3
inputs:
    .quad   in1, in2, in3, in4, in5
inputs_end:

    .text
    .p2align 2
// int is_palindrome(const char *s)
is_palindrome:
    mov     x1, x0                  // j = s
pal_end:
    ldrb    w2, [x1]
    cbz     w2, pal_found_end
    add     x1, x1, #1
    b       pal_end
pal_found_end:
    sub     x1, x1, #1              // j = last character
pal_loop:
    cmp     x0, x1
    b.hs    pal_yes                 // pointers met: it is a palindrome
    ldrb    w2, [x0], #1
    ldrb    w3, [x1], #-1
    cmp     w2, w3
    b.eq    pal_loop
    mov     w0, #0
    ret
pal_yes:
    mov     w0, #1
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
    bl      is_palindrome
    mov     w2, w0
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
