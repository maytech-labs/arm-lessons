// ex5.s - Exercise 16.5: a helper function that calls strlen and printf (macOS).
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

    .section __TEXT,__cstring
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
    bl      _strlen                 // x0 = length
    sub     sp, sp, #16
    stp     x19, x0, [sp]           // slot 0 = s, slot 1 = length
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    bl      _printf
    add     sp, sp, #16
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, word1@PAGE
    add     x0, x0, word1@PAGEOFF
    bl      show                    // our own function: no underscore needed
    adrp    x0, word2@PAGE
    add     x0, x0, word2@PAGEOFF
    bl      show
    adrp    x0, word3@PAGE
    add     x0, x0, word3@PAGEOFF
    bl      show
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
