// mystrchr.s - our own strchr: find a character, return a pointer to it (macOS).
//
// C version:
//     char *my_strchr(const char *s, int c) {
//         for (;; s++) {
//             if (*s == (char)c) return (char *)s;
//             if (*s == '\0')    return NULL;
//         }
//     }
//
// Build: make mystrchr
// Run:   ./mystrchr
// Expected output:
//     'w' -> "world.txt" (index 6)
//     '.' -> ".txt" (index 11)
//     'z' -> not found
//     '\0' -> "" (index 15)

    .section __TEXT,__const
text:
    .asciz  "hello world.txt"
fmt_found:
    .asciz  "'%c' -> \"%s\" (index %ld)\n"
fmt_nul:
    .asciz  "'\\0' -> \"%s\" (index %ld)\n"
fmt_missing:
    .asciz  "'%c' -> not found\n"

    .text
    .p2align 2
// char *my_strchr(const char *s, int c)
my_strchr:
    and     w1, w1, #0xff           // C converts c to a char first
strchr_loop:
    ldrb    w2, [x0]
    cmp     w2, w1
    b.eq    strchr_found            // test for c BEFORE testing for the end,
    cbz     w2, strchr_missing      // so that searching for '\0' works
    add     x0, x0, #1
    b       strchr_loop
strchr_missing:
    mov     x0, #0                  // NULL
strchr_found:
    ret

// void find(int c): search text for c and report
find:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     w19, w0                 // c
    adrp    x20, text@PAGE
    add     x20, x20, text@PAGEOFF
    mov     x1, x0
    mov     x0, x20
    bl      my_strchr
    cbz     x0, find_missing
    cbz     w19, find_nul
    mov     x2, x0                  // %s: the rest of the string from there
    sub     x3, x0, x20             // %ld: index = pointer - start
    mov     w1, w19                 // %c
    adrp    x0, fmt_found@PAGE
    add     x0, x0, fmt_found@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    b       find_done
find_nul:
    mov     x1, x0
    sub     x2, x0, x20
    adrp    x0, fmt_nul@PAGE
    add     x0, x0, fmt_nul@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    bl      _printf
    add     sp, sp, #16
    b       find_done
find_missing:
    mov     w1, w19
    adrp    x0, fmt_missing@PAGE
    add     x0, x0, fmt_missing@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    bl      _printf
    add     sp, sp, #16
find_done:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    mov     w0, #'w'
    bl      find
    mov     w0, #'.'
    bl      find
    mov     w0, #'z'
    bl      find
    mov     w0, #0
    bl      find
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
