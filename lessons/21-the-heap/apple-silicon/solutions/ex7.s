// ex7.s - a string builder: a growable, '\0'-terminated char buffer (lesson 21, macOS, exercise 21.7)
//
// Build: make ex7
// Run:   ./ex7
// Expected output:
//   len=4 cap=8 [the ]
//   len=10 cap=16 [the quick ]
//   len=16 cap=32 [the quick brown ]
//   len=19 cap=32 [the quick brown fox]

// struct SB { char *buf; long len; long cap; };   len does not count the '\0'
    .equ SB_BUF, 0
    .equ SB_LEN, 8
    .equ SB_CAP, 16
    .equ SB_SIZE, 24
    .equ SB_FIRST_CAP, 8

    .section __TEXT,__cstring
w0_the:
    .asciz "the "
w1_quick:
    .asciz "quick "
w2_brown:
    .asciz "brown "
w3_fox:
    .asciz "fox"
fmt:
    .asciz "len=%ld cap=%ld [%s]\n"

    .data
    .p2align 3
words:                              // const char *words[] = { ... };
    .quad w0_the, w1_quick, w2_brown, w3_fox
    .equ NWORDS, 4

    .text
    .p2align 2

// int sb_append(struct SB *sb, const char *s): 0 on success, -1 if out of memory
sb_append:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = sb, x20 = s
    stp x21, x22, [sp, #32]         // x21 = strlen(s), x22 = newcap
    mov x19, x0
    mov x20, x1

    mov  x0, x20
    bl   _strlen
    mov  x21, x0

    // needed = len + n + 1 (room for the '\0')
    ldr  x2, [x19, #SB_LEN]
    add  x2, x2, x21
    add  x2, x2, #1
    ldr  x22, [x19, #SB_CAP]
    cmp  x2, x22
    b.ls sb_append_copy             // already fits

    // newcap = cap ? cap : 8; while (newcap < needed) newcap *= 2;
    mov  x3, #SB_FIRST_CAP
    cmp  x22, #0
    csel x22, x3, x22, eq
sb_append_grow:
    cmp  x22, x2
    b.hs sb_append_grow_done
    lsl  x22, x22, #1
    b    sb_append_grow
sb_append_grow_done:
    ldr  x0, [x19, #SB_BUF]         // p = realloc(sb->buf, newcap);
    mov  x1, x22
    bl   _realloc
    cbz  x0, sb_append_fail
    str  x0, [x19, #SB_BUF]
    str  x22, [x19, #SB_CAP]

sb_append_copy:
    // copy s, including its '\0', to buf + len
    ldr  x0, [x19, #SB_BUF]
    ldr  x2, [x19, #SB_LEN]
    add  x0, x0, x2
    mov  x1, x20
sb_append_loop:
    ldrb w3, [x1], #1
    strb w3, [x0], #1
    cbnz w3, sb_append_loop
    add  x2, x2, x21                // sb->len += n;
    str  x2, [x19, #SB_LEN]
    mov  w0, #0
sb_append_done:
    ldp  x21, x22, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #48
    ret
sb_append_fail:
    mov  w0, #-1
    b    sb_append_done

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-64]!       // struct SB sb at [sp, #32]
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = i, x20 = &words

    str  xzr, [sp, #32 + SB_BUF]    // struct SB sb = { NULL, 0, 0 };
    str  xzr, [sp, #32 + SB_LEN]
    str  xzr, [sp, #32 + SB_CAP]

    adrp x20, words@PAGE
    add  x20, x20, words@PAGEOFF
    mov  x19, #0
main_loop:
    cmp  x19, #NWORDS
    b.ge main_loop_done
    add  x0, sp, #32
    ldr  x1, [x20, x19, lsl #3]
    bl   sb_append
    cbnz w0, main_fail
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    ldr  x1, [sp, #32 + SB_LEN]
    ldr  x2, [sp, #32 + SB_CAP]
    ldr  x3, [sp, #32 + SB_BUF]
    sub  sp, sp, #32                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    str  x3, [sp, #16]
    bl   _printf
    add  sp, sp, #32
    add  x19, x19, #1
    b    main_loop
main_loop_done:
    mov  w19, #0                    // exit status 0
main_free:
    ldr  x0, [sp, #32 + SB_BUF]     // free(sb.buf);
    bl   _free
    mov  w0, w19
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #64
    ret
main_fail:
    mov  w19, #1
    b    main_free
