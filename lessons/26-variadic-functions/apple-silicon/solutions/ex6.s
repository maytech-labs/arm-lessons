// ex6.s - exercise 26.6 (macOS): char *concat(int n, ...) joins n strings
// into a new malloc'd string, walking the arguments twice.
// On macOS va_copy(ap2, ap) is just copying a pointer.
//
// Build and run:
//     make ex6
//     ./ex6
// Expected output:
//     [foobarbaz]
//     []
//     [one two three four five six seven eight nine]

    .text
    .globl  _concat
    .p2align 2
_concat:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]

    add     x23, sp, #64                    // va_start: x23 = ap
    mov     x24, x23                        // va_copy:  x24 = ap2
    mov     w19, w0                         // n

    mov     x20, #0                         // total length
    mov     w21, w19
1:
    cbz     w21, 2f
    ldr     x0, [x23], #8                   // va_arg(ap, char *)
    bl      _strlen
    add     x20, x20, x0
    sub     w21, w21, #1
    b       1b
2:
    add     x0, x20, #1
    bl      _malloc
    mov     x21, x0                         // buf
    mov     x22, x0                         // end
    strb    wzr, [x22]
3:
    cbz     w19, 4f
    ldr     x1, [x24], #8                   // va_arg(ap2, char *)
    mov     x0, x22
    bl      _strcpy
    mov     x0, x22
    bl      _strlen
    add     x22, x22, x0
    sub     w19, w19, #1
    b       3b
4:
    mov     x0, x21
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// show: printf("[%s]\n", s); free(s).
    .p2align 2
show:
    sub     sp, sp, #32
    stp     x29, x30, [sp, #16]
    add     x29, sp, #16
    str     x0, [sp, #8]                    // keep s
    str     x0, [sp]                        // printf's variadic slot
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    bl      _printf
    ldr     x0, [sp, #8]
    bl      _free
    ldp     x29, x30, [sp, #16]
    add     sp, sp, #32
    ret

    .macro  lea reg, sym
    adrp    \reg, \sym@PAGE
    add     \reg, \reg, \sym@PAGEOFF
    .endm

    .globl  _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    sub     sp, sp, #32
    lea     x9, s_foo
    lea     x10, s_bar
    stp     x9, x10, [sp]
    lea     x9, s_baz
    str     x9, [sp, #16]
    mov     w0, #3
    bl      _concat
    add     sp, sp, #32
    bl      show

    mov     w0, #0
    bl      _concat
    bl      show

    sub     sp, sp, #80                     // nine slots
    lea     x9, word1
    lea     x10, word2
    stp     x9, x10, [sp]
    lea     x9, word3
    lea     x10, word4
    stp     x9, x10, [sp, #16]
    lea     x9, word5
    lea     x10, word6
    stp     x9, x10, [sp, #32]
    lea     x9, word7
    lea     x10, word8
    stp     x9, x10, [sp, #48]
    lea     x9, word9
    str     x9, [sp, #64]
    mov     w0, #9
    bl      _concat
    add     sp, sp, #80
    bl      show

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

    .section __TEXT,__cstring
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
