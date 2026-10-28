// reverse.s - reverse a string in place with two pointers (macOS).
//
// C version:
//     void reverse(char *s) {
//         char *i = s, *j = s + strlen(s) - 1;
//         while (i < j) { char t = *i; *i++ = *j; *j-- = t; }
//     }
//
// Build: make reverse
// Run:   ./reverse
// Expected output:
//     stressed -> desserts
//     abc -> cba
//     a -> a
//      ->

    .data                           // writable: reverse changes them
word1:
    .asciz  "stressed"
word2:
    .asciz  "abc"
word3:
    .asciz  "a"
word4:
    .asciz  ""

    .section __TEXT,__const
fmt_before:
    .asciz  "%s -> "

    .text
    .p2align 2
// void reverse(char *s)
reverse:
    mov     x1, x0                  // j = s
rev_find_end:
    ldrb    w2, [x1]
    cbz     w2, rev_found_end
    add     x1, x1, #1
    b       rev_find_end
rev_found_end:
    sub     x1, x1, #1              // j = last character (s - 1 if empty)
rev_loop:
    cmp     x0, x1                  // while (i < j), as unsigned addresses
    b.hs    rev_done
    ldrb    w2, [x0]                // swap *i and *j
    ldrb    w3, [x1]
    strb    w3, [x0], #1            // *i++ = old *j
    strb    w2, [x1], #-1           // *j-- = old *i
    b       rev_loop
rev_done:
    ret

// void show(char *s): print "s -> reversed"
show:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0
    mov     x1, x0
    adrp    x0, fmt_before@PAGE
    add     x0, x0, fmt_before@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    bl      _printf
    add     sp, sp, #16
    mov     x0, x19
    bl      reverse
    mov     x0, x19
    bl      _puts
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
    bl      show
    adrp    x0, word2@PAGE
    add     x0, x0, word2@PAGEOFF
    bl      show
    adrp    x0, word3@PAGE
    add     x0, x0, word3@PAGEOFF
    bl      show
    adrp    x0, word4@PAGE
    add     x0, x0, word4@PAGEOFF
    bl      show
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
