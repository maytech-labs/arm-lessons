// ex4.s - qsort an array of strings with a comparator that calls strcmp (lesson 24, exercise 24.4, macOS)
//
// Build: make ex4
// Run:   ./ex4
// Expected output:
//   apple
//   banana
//   cherry
//   fig
//   pear
//
// The C version:
//   int cmp_str(const void *pa, const void *pb) {
//       const char *a = *(const char *const *)pa;   // qsort passes &words[i],
//       const char *b = *(const char *const *)pb;   // a pointer to a pointer
//       return strcmp(a, b);
//   }
//   const char *words[5] = {"pear", "apple", "fig", "banana", "cherry"};
//   int main(void) {
//       qsort(words, 5, sizeof(char *), cmp_str);
//       for (long i = 0; i < 5; i++) puts(words[i]);
//   }

    .equ N, 5

    .text
    .global _main
    .p2align 2

cmp_str:
    stp x29, x30, [sp, #-16]!       // not a leaf any more: it calls strcmp
    mov x29, sp
    ldr x0, [x0]                    // a = *pa
    ldr x1, [x1]                    // b = *pb
    bl  _strcmp                      // its return value is ours
    ldp x29, x30, [sp], #16
    ret

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    adrp x0, words@PAGE
    add  x0, x0, words@PAGEOFF
    mov  x1, #N
    mov  x2, #8                     // each element is a pointer: 8 bytes
    adr  x3, cmp_str
    bl   _qsort

    adrp x19, words@PAGE
    add  x19, x19, words@PAGEOFF
    mov  x20, #0
main_loop:
    cmp  x20, #N
    b.ge main_done
    ldr  x0, [x19, x20, lsl #3]
    bl   _puts
    add  x20, x20, #1
    b    main_loop
main_done:
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .data                           // pointers (need relocation) that qsort rearranges
    .p2align 3
words: .quad w_pear, w_apple, w_fig, w_banana, w_cherry

    .section __TEXT,__cstring
w_pear:   .asciz "pear"
w_apple:  .asciz "apple"
w_fig:    .asciz "fig"
w_banana: .asciz "banana"
w_cherry: .asciz "cherry"
