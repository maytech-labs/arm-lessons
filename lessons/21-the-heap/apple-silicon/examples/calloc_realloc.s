// calloc_realloc.s - calloc gives zeroed memory, realloc grows a block (lesson 21, macOS)
//
// Build: make calloc_realloc
// Run:   ./calloc_realloc
// Expected output:
//   after calloc: 0 0 0 0
//   after fill: 1 2 3 4
//   after realloc: 1 2 3 4
//   after second fill: 1 2 3 4 5 6 7 8

    .section __TEXT,__cstring
lbl_calloc:
    .asciz "after calloc"
lbl_fill:
    .asciz "after fill"
lbl_realloc:
    .asciz "after realloc"
lbl_fill2:
    .asciz "after second fill"
fmt_label:
    .asciz "%s:"
fmt_elem:
    .asciz " %ld"

    .text
    .p2align 2

// void print_array(const char *label, long *a, long n)
// prints "label: a[0] a[1] ... a[n-1]" and a newline
print_array:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = a, x20 = n
    str x21, [sp, #32]              // x21 = i
    mov x19, x1
    mov x20, x2

    mov  x1, x0                     // printf("%s:", label);
    adrp x0, fmt_label@PAGE
    add  x0, x0, fmt_label@PAGEOFF
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16

    mov  x21, #0
print_array_loop:
    cmp  x21, x20
    b.ge print_array_done
    adrp x0, fmt_elem@PAGE          // printf(" %ld", a[i]);
    add  x0, x0, fmt_elem@PAGEOFF
    ldr  x1, [x19, x21, lsl #3]
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16
    add  x21, x21, #1
    b    print_array_loop
print_array_done:
    mov  w0, #10                    // putchar('\n');   10 is '\n'
    bl   _putchar

    ldr  x21, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #48
    ret

// void fill(long *a, long from, long to): a[i] = i + 1 for from <= i < to
// (a leaf function: no calls, so no frame needed)
fill:
    cmp  x1, x2
    b.ge fill_done
    add  x3, x1, #1
    str  x3, [x0, x1, lsl #3]
    add  x1, x1, #1
    b    fill
fill_done:
    ret

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = p

    // long *p = calloc(4, sizeof(long));   4 elements of 8 bytes, all zero
    mov  x0, #4
    mov  x1, #8
    bl   _calloc
    cbz  x0, main_fail
    mov  x19, x0

    adrp x0, lbl_calloc@PAGE
    add  x0, x0, lbl_calloc@PAGEOFF
    mov  x1, x19
    mov  x2, #4
    bl   print_array

    mov  x0, x19                    // fill(p, 0, 4);
    mov  x1, #0
    mov  x2, #4
    bl   fill
    adrp x0, lbl_fill@PAGE
    add  x0, x0, lbl_fill@PAGEOFF
    mov  x1, x19
    mov  x2, #4
    bl   print_array

    // long *tmp = realloc(p, 8 * sizeof(long));
    // if (tmp == NULL) { free(p); return 1; }
    // p = tmp;
    mov  x0, x19
    mov  x1, #(8 * 8)
    bl   _realloc
    cbz  x0, main_realloc_fail      // p (x19) is still valid here
    mov  x19, x0                    // only now replace p

    adrp x0, lbl_realloc@PAGE       // the old 4 values were copied over
    add  x0, x0, lbl_realloc@PAGEOFF
    mov  x1, x19
    mov  x2, #4                     // elements 4..7 are not initialised yet
    bl   print_array

    mov  x0, x19                    // fill(p, 4, 8);
    mov  x1, #4
    mov  x2, #8
    bl   fill
    adrp x0, lbl_fill2@PAGE
    add  x0, x0, lbl_fill2@PAGEOFF
    mov  x1, x19
    mov  x2, #8
    bl   print_array

    mov  x0, x19                    // free(p);
    bl   _free
    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_realloc_fail:
    mov  x0, x19                    // the old block is ours: free it
    bl   _free
main_fail:
    mov  w0, #1
    b    main_done
