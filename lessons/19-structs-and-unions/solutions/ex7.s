// ex7.s - Exercise 19.7: a tagged union.
//
// C:      enum { INT, STR };
//         struct value { int tag; union { long i; const char *s; } u; };  // 16 bytes
//         struct value v[3] = {{INT, .u.i = 42}, {STR, .u.s = "hello"}, {INT, .u.i = -1}};
//         for each: tag == INT ? printf("int %ld\n", v.u.i) : printf("str %s\n", v.u.s);
//
// Build:  make
// Run:    ./ex7
// Expected output:
//   int 42
//   str hello
//   int -1

    .global main

    .equ TAG_INT, 0
    .equ TAG_STR, 1
    .equ VALUE_TAG, 0           // int at 0, then 4 bytes of padding
    .equ VALUE_U, 8             // the union: aligned to 8 (long and pointer)
    .equ VALUE_SIZE, 16

    .section .rodata
hello:  .asciz "hello"
fmt_i:  .asciz "int %ld\n"
fmt_s:  .asciz "str %s\n"

    .data
    .p2align 3
values:
    .word TAG_INT, 0            // tag + padding
    .quad 42
    .word TAG_STR, 0
    .quad hello                 // the address of the string
    .word TAG_INT, 0
    .quad -1
    .equ COUNT, (. - values) / VALUE_SIZE

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    adrp x19, values
    add x19, x19, :lo12:values
    mov x20, #COUNT
loop:
    ldr w9, [x19, #VALUE_TAG]
    ldr x1, [x19, #VALUE_U]     // the same 8 bytes, whichever member it is
    adrp x0, fmt_i
    add x0, x0, :lo12:fmt_i
    adrp x10, fmt_s
    add x10, x10, :lo12:fmt_s
    cmp w9, #TAG_STR
    csel x0, x10, x0, eq        // the tag says how to interpret them
    bl printf
    add x19, x19, #VALUE_SIZE
    subs x20, x20, #1
    b.ne loop

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
