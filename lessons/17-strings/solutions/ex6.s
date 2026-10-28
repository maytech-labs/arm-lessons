// ex6.s - Exercise 17.6: capitalise the first letter of every word, in place.
//
// C version:
//     void capitalize(char *s) {
//         int start = 1;                       // at the start of a word?
//         for (; *s; s++) {
//             if (*s == ' ') start = 1;
//             else {
//                 *s = start ? toupper(*s) : tolower(*s);
//                 start = 0;
//             }
//         }
//     }
//
// Build: make ex6
// Run:   ./ex6
// Expected output:
//     Hello Big World
//     Assembly Is Fun, Really

    .data
text1:
    .asciz  "hello big wORLD"
text2:
    .asciz  "assembly IS fun, really"

    .text
    .p2align 2
// void capitalize(char *s)   (a leaf: the case changes are inlined)
capitalize:
    mov     w1, #1                  // start = 1
cap_loop:
    ldrb    w2, [x0]
    cbz     w2, cap_done
    cmp     w2, #' '
    b.ne    cap_letter
    mov     w1, #1
    b       cap_next
cap_letter:
    cbz     w1, cap_lower
    sub     w3, w2, #'a'            // toupper
    cmp     w3, #25
    b.hi    cap_store
    and     w2, w2, #~0x20
    b       cap_store
cap_lower:
    sub     w3, w2, #'A'            // tolower
    cmp     w3, #25
    b.hi    cap_store
    orr     w2, w2, #0x20
cap_store:
    strb    w2, [x0]
    mov     w1, #0                  // no longer at the start
cap_next:
    add     x0, x0, #1
    b       cap_loop
cap_done:
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, text1
    add     x0, x0, :lo12:text1
    bl      capitalize
    adrp    x0, text1
    add     x0, x0, :lo12:text1
    bl      puts
    adrp    x0, text2
    add     x0, x0, :lo12:text2
    bl      capitalize
    adrp    x0, text2
    add     x0, x0, :lo12:text2
    bl      puts
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
