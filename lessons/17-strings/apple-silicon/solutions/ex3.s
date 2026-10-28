// ex3.s - Exercise 17.3: my_strrchr, the LAST occurrence of a character (macOS).
//
// C version:
//     char *my_strrchr(const char *s, int c) {
//         const char *last = NULL;
//         for (;; s++) {
//             if (*s == (char)c) last = s;
//             if (*s == '\0') return (char *)last;
//         }
//     }
//
// Build: make ex3
// Run:   ./ex3
// Expected output:
//     mine: /bin  libc: /bin
//     mine: .gz  libc: .gz
//     mine: (none)  libc: (none)

    .section __TEXT,__const
path:
    .asciz  "/usr/local/bin"
file:
    .asciz  "notes.tar.gz"
fmt:
    .asciz  "mine: %s  libc: %s\n"
none:
    .asciz  "(none)"

    .text
    .p2align 2
// char *my_strrchr(const char *s, int c)
my_strrchr:
    and     w1, w1, #0xff
    mov     x2, #0                  // last = NULL
strrchr_loop:
    ldrb    w3, [x0]
    cmp     w3, w1
    csel    x2, x0, x2, eq          // if (*s == c) last = s
    cbz     w3, strrchr_done
    add     x0, x0, #1
    b       strrchr_loop
strrchr_done:
    mov     x0, x2
    ret

// void compare(const char *s, int c)
compare:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    mov     x19, x0
    mov     w20, w1
    bl      my_strrchr
    mov     x21, x0                 // mine
    mov     x0, x19
    mov     w1, w20
    bl      _strrchr                // libc's
    adrp    x3, none@PAGE           // replace NULL by "(none)" for printing
    add     x3, x3, none@PAGEOFF
    cmp     x0, #0
    csel    x2, x3, x0, eq
    cmp     x21, #0
    csel    x1, x3, x21, eq
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    bl      _printf
    add     sp, sp, #16
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, path@PAGE
    add     x0, x0, path@PAGEOFF
    mov     w1, #'/'
    bl      compare
    adrp    x0, file@PAGE
    add     x0, x0, file@PAGEOFF
    mov     w1, #'.'
    bl      compare
    adrp    x0, path@PAGE
    add     x0, x0, path@PAGEOFF
    mov     w1, #'x'
    bl      compare
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
