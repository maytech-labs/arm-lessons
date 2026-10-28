// ex6.s - exercise 26.6: char *concat(int n, ...) joins n strings into a
// new malloc'd string, walking the arguments twice with va_copy.
//
// The C version:
//     char *concat(int n, ...) {
//         va_list ap, ap2;
//         va_start(ap, n);
//         va_copy(ap2, ap);
//         size_t total = 0;
//         for (int i = 0; i < n; i++) total += strlen(va_arg(ap, char *));
//         char *buf = malloc(total + 1), *end = buf;
//         *buf = '\0';
//         for (int i = 0; i < n; i++) {
//             strcpy(end, va_arg(ap2, char *));
//             end += strlen(end);
//         }
//         va_end(ap2);
//         va_end(ap);
//         return buf;
//     }
//
// Build and run:
//     make ex6
//     ./ex6
// Expected output:
//     [foobarbaz]
//     []
//     [one two three four five six seven eight nine]

    .equ VA_STACK,    0
    .equ VA_GR_TOP,   8
    .equ VA_VR_TOP,  16
    .equ VA_GR_OFFS, 24
    .equ VA_VR_OFFS, 28

// Frame of concat (176 bytes):
//     sp+0    x29, x30
//     sp+16   x19, x20
//     sp+32   x21, x22
//     sp+48   va_list ap        (32 bytes)
//     sp+80   va_list ap2       (32 bytes)
//     sp+112  x1 .. x7          (GR save area, ends at sp+168)
//     sp+176  = entry sp
    .equ AP,       48
    .equ AP2,      80
    .equ GR_SAVE, 112
    .equ GR_TOP,  168
    .equ FRAME,   176

    .text
    .global concat
    .p2align 2
concat:
    stp     x29, x30, [sp, #-FRAME]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x1, x2, [sp, #GR_SAVE]
    stp     x3, x4, [sp, #GR_SAVE + 16]
    stp     x5, x6, [sp, #GR_SAVE + 32]
    str     x7, [sp, #GR_SAVE + 48]

    // va_start(ap, n)
    add     x9, sp, #FRAME
    str     x9, [sp, #AP + VA_STACK]
    add     x9, sp, #GR_TOP
    str     x9, [sp, #AP + VA_GR_TOP]
    str     xzr, [sp, #AP + VA_VR_TOP]
    mov     w9, #-56
    str     w9, [sp, #AP + VA_GR_OFFS]
    str     wzr, [sp, #AP + VA_VR_OFFS]

    // va_copy(ap2, ap): copy the 32-byte struct
    ldp     x9, x10, [sp, #AP]
    stp     x9, x10, [sp, #AP2]
    ldp     x9, x10, [sp, #AP + 16]
    stp     x9, x10, [sp, #AP2 + 16]

    mov     w19, w0                         // x19 = n
    // First walk: total length.
    mov     x20, #0                         // x20 = total
    mov     w21, w19                        // w21 = counter
1:
    cbz     w21, 2f
    add     x0, sp, #AP
    bl      next_gr
    ldr     x0, [x0]                        // va_arg(ap, char *)
    bl      strlen
    add     x20, x20, x0
    sub     w21, w21, #1
    b       1b
2:
    add     x0, x20, #1
    bl      malloc
    mov     x21, x0                         // x21 = buf (the result)
    mov     x22, x0                         // x22 = end
    strb    wzr, [x22]                      // *buf = '\0' (for n == 0)

    // Second walk, with the copy.
3:
    cbz     w19, 4f
    add     x0, sp, #AP2
    bl      next_gr
    ldr     x1, [x0]                        // va_arg(ap2, char *)
    mov     x0, x22
    bl      strcpy                          // strcpy(end, s)
    mov     x0, x22
    bl      strlen
    add     x22, x22, x0                    // end += strlen(end)
    sub     w19, w19, #1
    b       3b
4:
    mov     x0, x21
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #FRAME
    ret

// next_gr: x0 = &va_list. Returns x0 = address of the next GP argument.
    .p2align 2
next_gr:
    ldr     w9, [x0, #VA_GR_OFFS]
    tbz     w9, #31, 1f
    add     w10, w9, #8
    str     w10, [x0, #VA_GR_OFFS]
    ldr     x10, [x0, #VA_GR_TOP]
    add     x0, x10, w9, sxtw
    ret
1:
    ldr     x10, [x0, #VA_STACK]
    add     x11, x10, #8
    str     x11, [x0, #VA_STACK]
    mov     x0, x10
    ret

// show: print "[s]\n" and free s.
    .p2align 2
show:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0
    mov     x1, x0
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    bl      printf
    mov     x0, x19
    bl      free
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// Load the address of a string into a register.
    .macro  lea reg, sym
    adrp    \reg, \sym
    add     \reg, \reg, :lo12:\sym
    .endm

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     w0, #3
    lea     x1, s_foo
    lea     x2, s_bar
    lea     x3, s_baz
    bl      concat
    bl      show

    mov     w0, #0
    bl      concat
    bl      show

    // Nine strings: seven in x1-x7, the last two on the stack.
    sub     sp, sp, #16
    lea     x9, word8
    lea     x10, word9
    stp     x9, x10, [sp]
    mov     w0, #9
    lea     x1, word1
    lea     x2, word2
    lea     x3, word3
    lea     x4, word4
    lea     x5, word5
    lea     x6, word6
    lea     x7, word7
    bl      concat
    add     sp, sp, #16
    bl      show

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section .rodata
fmt:    .asciz  "[%s]\n"
s_foo:  .asciz  "foo"
s_bar:  .asciz  "bar"
s_baz:  .asciz  "baz"
word1:  .asciz  "one"
word2:  .asciz  " two"
word3:  .asciz  " three"
word4:  .asciz  " four"
word5:  .asciz  " five"
word6:  .asciz  " six"
word7:  .asciz  " seven"
word8:  .asciz  " eight"
word9:  .asciz  " nine"
