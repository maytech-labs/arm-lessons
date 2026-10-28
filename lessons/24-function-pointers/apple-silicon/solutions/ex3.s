// ex3.s - qsort in descending order, then bsearch the sorted array (lesson 24, exercise 24.3, macOS)
//
// Build: make ex3
// Run:   ./ex3
// Expected output:
//   12 12 7 5 1 0 -3
//   found 7 at index 2
//
// The C version:
//   int cmp_desc(const void *pa, const void *pb) {
//       int a = *(const int *)pa, b = *(const int *)pb;
//       return (a < b) - (a > b);       // the opposite of ascending
//   }
//   int nums[7] = {5, 12, -3, 7, 0, 12, 1};
//   int main(void) {
//       qsort(nums, 7, sizeof(int), cmp_desc);
//       print_ints(nums, 7);
//       int key = 7;
//       int *p = bsearch(&key, nums, 7, sizeof(int), cmp_desc);   // same order!
//       printf("found %d at index %ld\n", *p, (long)(p - nums));
//   }

    .equ N, 7

    .text
    .global _main
    .p2align 2

cmp_desc:
    ldr  w2, [x0]
    ldr  w3, [x1]
    cmp  w2, w3
    cset w0, lt                     // (a < b)
    cset w4, gt                     // (a > b)
    sub  w0, w0, w4
    ret

// void print_ints(const int *a, long n) - prints "a[0] a[1] ... a[n-1]\n"
print_ints:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    sub sp, sp, #16                 // room for printf's variadic argument
    mov x19, x0                     // a
    mov x20, x1                     // n
    mov x21, #0                     // i
print_ints_loop:
    cmp  x21, x20
    b.ge print_ints_done
    adrp x0, fmt_first@PAGE         // "%d" for the first number...
    add  x0, x0, fmt_first@PAGEOFF
    adrp x1, fmt_next@PAGE          // ...and " %d" for the rest
    add  x1, x1, fmt_next@PAGEOFF
    cmp  x21, #0
    csel x0, x0, x1, eq
    ldr  w9, [x19, x21, lsl #2]
    str  x9, [sp]                   // a[i] goes on the stack, not in w1
    bl   _printf
    add  x21, x21, #1
    b    print_ints_loop
print_ints_done:
    mov  w0, #'\n'
    bl   _putchar
    add  sp, sp, #16
    ldr  x21, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #48
    ret

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp

    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #N
    mov  x2, #4
    adr  x3, cmp_desc
    bl   _qsort

    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #N
    bl   print_ints

    mov  w9, #7
    str  w9, [sp, #16]              // key = 7, on the stack so it has an address
    add  x0, sp, #16
    adrp x1, nums@PAGE
    add  x1, x1, nums@PAGEOFF
    mov  x2, #N
    mov  x3, #4
    adr  x4, cmp_desc
    bl   _bsearch
    cbz  x0, main_done              // not found: print nothing
    ldr  w9, [x0]
    adrp x10, nums@PAGE
    add  x10, x10, nums@PAGEOFF
    sub  x10, x0, x10
    asr  x10, x10, #2
    sub  sp, sp, #16                // room for two variadic arguments
    stp  x9, x10, [sp]
    adrp x0, fmt_found@PAGE
    add  x0, x0, fmt_found@PAGEOFF
    bl   _printf
    add  sp, sp, #16
main_done:
    mov w0, #0
    ldp x29, x30, [sp], #32
    ret

    .data
    .p2align 2
nums: .word 5, 12, -3, 7, 0, 12, 1

    .section __TEXT,__cstring
fmt_first: .asciz "%d"
fmt_next:  .asciz " %d"
fmt_found: .asciz "found %d at index %ld\n"
