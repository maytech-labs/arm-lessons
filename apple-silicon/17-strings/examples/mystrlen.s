// mystrlen.s - our own strlen, checked against the C library's (macOS).
//
// C version:
//     size_t my_strlen(const char *s) {
//         const char *p = s;
//         while (*p != '\0') p++;
//         return p - s;
//     }
//
// Build: make mystrlen
// Run:   ./mystrlen
// Expected output:
//     my_strlen("hello") = 5, strlen = 5
//     my_strlen("") = 0, strlen = 0
//     my_strlen("a longer string, with spaces") = 28, strlen = 28

    .section __TEXT,__const
fmt:
    .asciz  "my_strlen(\"%s\") = %ld, strlen = %ld\n"
str_a:
    .asciz  "hello"
str_b:
    .asciz  ""
str_c:
    .asciz  "a longer string, with spaces"

    .text
    .p2align 2
// size_t my_strlen(const char *s)
my_strlen:
    mov     x1, x0                  // p = s
strlen_loop:
    ldrb    w2, [x1], #1            // c = *p++
    cbnz    w2, strlen_loop         // keep going until c == 0
    sub     x0, x1, x0              // p is now one past the 0 byte,
    sub     x0, x0, #1              // so the length is p - s - 1
    ret

// void check(const char *s): print my_strlen(s) next to strlen(s)
check:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     x19, x0                 // s
    bl      my_strlen
    mov     x20, x0                 // mine
    mov     x0, x19
    bl      _strlen                 // libc's
    mov     x3, x0
    mov     x2, x20
    mov     x1, x19
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, str_a@PAGE
    add     x0, x0, str_a@PAGEOFF
    bl      check
    adrp    x0, str_b@PAGE
    add     x0, x0, str_b@PAGEOFF
    bl      check
    adrp    x0, str_c@PAGE
    add     x0, x0, str_c@PAGEOFF
    bl      check
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
