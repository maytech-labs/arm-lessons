// ex4.s - count letters with a calloc'd array of 26 ints (lesson 21, exercise 21.4)
//
// Build: make ex4
// Run:   ./ex4
// Expected output:
//   d: 1
//   e: 1
//   h: 1
//   l: 3
//   o: 2
//   r: 1
//   w: 1

    .equ LETTERS, 26
    .equ INT_SIZE, 4                // sizeof(int)

    .section .rodata
text:
    .asciz "hello world"
fmt:
    .asciz "%c: %d\n"

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = counts, x20 = i

    // int *counts = calloc(26, sizeof(int));   every count starts at 0
    mov  x0, #LETTERS
    mov  x1, #INT_SIZE
    bl   calloc
    cbz  x0, main_fail
    mov  x19, x0

    // for (p = text; *p; p++) if ('a' <= *p && *p <= 'z') counts[*p - 'a']++;
    adrp x1, text
    add  x1, x1, :lo12:text
main_count:
    ldrb w2, [x1], #1
    cbz  w2, main_count_done
    sub  w2, w2, #'a'               // index = c - 'a'
    cmp  w2, #LETTERS
    b.hs main_count                 // unsigned compare: also skips c < 'a'
    ldr  w3, [x19, w2, uxtw #2]     // counts[index]   (4-byte elements: shift 2)
    add  w3, w3, #1
    str  w3, [x19, w2, uxtw #2]
    b    main_count
main_count_done:

    // for (i = 0; i < 26; i++) if (counts[i]) printf("%c: %d\n", 'a' + i, counts[i]);
    mov  x20, #0
main_print:
    cmp  x20, #LETTERS
    b.ge main_print_done
    ldr  w2, [x19, x20, lsl #2]
    cbz  w2, main_print_next
    adrp x0, fmt
    add  x0, x0, :lo12:fmt
    add  w1, w20, #'a'
    bl   printf
main_print_next:
    add  x20, x20, #1
    b    main_print
main_print_done:

    mov  x0, x19                    // free(counts);
    bl   free
    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
