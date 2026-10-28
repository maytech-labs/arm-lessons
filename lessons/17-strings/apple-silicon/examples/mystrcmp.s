// mystrcmp.s - our own strcmp and strncmp, checked against the C library's (macOS).
//
// C version:
//     int my_strcmp(const char *a, const char *b) {
//         unsigned char ca, cb;
//         do {
//             ca = *a++;
//             cb = *b++;
//         } while (ca == cb && ca != '\0');
//         return ca - cb;
//     }
//     int my_strncmp(const char *a, const char *b, size_t n);  // at most n chars
//
// The C standard only promises the SIGN of the result (negative, 0, positive),
// so we print sign(result): -1, 0 or 1.
//
// Build: make mystrcmp
// Run:   ./mystrcmp
// Expected output:
//     strcmp("apple", "apricot"): mine -1, libc -1
//     strcmp("apple", "apple"): mine 0, libc 0
//     strcmp("pear", "peach"): mine 1, libc 1
//     strcmp("app", "apple"): mine -1, libc -1
//     strncmp("apple", "apricot", 2): mine 0, libc 0
//     strncmp("apple", "apricot", 3): mine -1, libc -1

    .section __TEXT,__const
fmt_cmp:
    .asciz  "strcmp(\"%s\", \"%s\"): mine %d, libc %d\n"
fmt_ncmp:
    .asciz  "strncmp(\"%s\", \"%s\", %ld): mine %d, libc %d\n"
apple:
    .asciz  "apple"
apricot:
    .asciz  "apricot"
pear:
    .asciz  "pear"
peach:
    .asciz  "peach"
app:
    .asciz  "app"

    .text
    .p2align 2
// int my_strcmp(const char *a, const char *b)
my_strcmp:
strcmp_loop:
    ldrb    w2, [x0], #1            // ca = *a++  (ldrb: unsigned, as C requires)
    ldrb    w3, [x1], #1            // cb = *b++
    cmp     w2, w3
    b.ne    strcmp_done             // different: done
    cbnz    w2, strcmp_loop         // same and not the end: keep going
strcmp_done:
    sub     w0, w2, w3              // ca - cb (0 if both ended together)
    ret

// int my_strncmp(const char *a, const char *b, size_t n)
my_strncmp:
strncmp_loop:
    cbz     x2, strncmp_equal       // compared n characters: equal so far
    sub     x2, x2, #1
    ldrb    w3, [x0], #1
    ldrb    w4, [x1], #1
    cmp     w3, w4
    b.ne    strncmp_done
    cbnz    w3, strncmp_loop
strncmp_done:
    sub     w0, w3, w4
    ret
strncmp_equal:
    mov     w0, #0
    ret

// int sign(int x): -1, 0 or 1
sign:
    cmp     w0, #0
    cset    w0, gt                  // w0 = (x > 0)
    csinv   w0, w0, wzr, ge         // if !(x >= 0) w0 = ~0 = -1
    ret

// void check_cmp(const char *a, const char *b)
check_cmp:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    mov     x19, x0
    mov     x20, x1
    bl      my_strcmp
    bl      sign
    mov     w21, w0                 // sign of mine
    mov     x0, x19
    mov     x1, x20
    bl      _strcmp
    bl      sign
    mov     w4, w0                  // sign of libc's
    mov     w3, w21
    mov     x2, x20
    mov     x1, x19
    adrp    x0, fmt_cmp@PAGE
    add     x0, x0, fmt_cmp@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    str     x4, [sp, #24]
    bl      _printf
    add     sp, sp, #32
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// void check_ncmp(const char *a, const char *b, size_t n)
check_ncmp:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    mov     x19, x0
    mov     x20, x1
    mov     x21, x2
    bl      my_strncmp
    bl      sign
    mov     w22, w0
    mov     x0, x19
    mov     x1, x20
    mov     x2, x21
    bl      _strncmp
    bl      sign
    mov     w5, w0
    mov     w4, w22
    mov     x3, x21
    mov     x2, x20
    mov     x1, x19
    adrp    x0, fmt_ncmp@PAGE
    add     x0, x0, fmt_ncmp@PAGEOFF
    sub     sp, sp, #48         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    str     x4, [sp, #24]
    str     x5, [sp, #32]
    bl      _printf
    add     sp, sp, #48
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, apple@PAGE
    add     x0, x0, apple@PAGEOFF
    adrp    x1, apricot@PAGE
    add     x1, x1, apricot@PAGEOFF
    bl      check_cmp

    adrp    x0, apple@PAGE
    add     x0, x0, apple@PAGEOFF
    mov     x1, x0
    bl      check_cmp

    adrp    x0, pear@PAGE
    add     x0, x0, pear@PAGEOFF
    adrp    x1, peach@PAGE
    add     x1, x1, peach@PAGEOFF
    bl      check_cmp

    adrp    x0, app@PAGE
    add     x0, x0, app@PAGEOFF
    adrp    x1, apple@PAGE
    add     x1, x1, apple@PAGEOFF
    bl      check_cmp

    adrp    x0, apple@PAGE
    add     x0, x0, apple@PAGEOFF
    adrp    x1, apricot@PAGE
    add     x1, x1, apricot@PAGEOFF
    mov     x2, #2
    bl      check_ncmp

    adrp    x0, apple@PAGE
    add     x0, x0, apple@PAGEOFF
    adrp    x1, apricot@PAGE
    add     x1, x1, apricot@PAGEOFF
    mov     x2, #3
    bl      check_ncmp

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
