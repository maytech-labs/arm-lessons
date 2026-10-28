// ex5.s - Exercise 16.5: a helper function that calls strlen and printf.
//
// C version:
//     void show(const char *s) { printf("\"%s\" has %ld characters\n", s, strlen(s)); }
//     int main(void) { show("cat"); show("assembly"); show(""); return 0; }
//
// Build: make ex5
// Run:   ./ex5
// Expected output:
//     "cat" has 3 characters
//     "assembly" has 8 characters
//     "" has 0 characters

    .section .rodata
fmt:
    .asciz  "\"%s\" has %ld characters\n"
word1:
    .asciz  "cat"
word2:
    .asciz  "assembly"
word3:
    .asciz  ""

    .text
    .p2align 2
// void show(const char *s)
show:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0                 // keep s across the strlen call
    bl      strlen                  // x0 = length
    mov     x2, x0                  // 3rd printf argument
    mov     x1, x19                 // 2nd
    adrp    x0, fmt                 // 1st
    add     x0, x0, :lo12:fmt
    bl      printf
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, word1
    add     x0, x0, :lo12:word1
    bl      show
    adrp    x0, word2
    add     x0, x0, :lo12:word2
    bl      show
    adrp    x0, word3
    add     x0, x0, :lo12:word3
    bl      show
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
