// qsort_ints.s - sort with the C library's qsort, search with bsearch (lesson 24, macOS)
//
// Build: make qsort_ints
// Run:   ./qsort_ints
// Expected output:
//   before: 42 -7 19 0 88 3 -20 19
//   after:  -20 -7 0 3 19 19 42 88
//   found 88 at index 7
//   5 is not in the array
//
// The C version:
//   int cmp_int(const void *pa, const void *pb) {
//       int a = *(const int *)pa, b = *(const int *)pb;
//       return (a > b) - (a < b);          // 1, 0 or -1
//   }
//   int nums[8] = {42, -7, 19, 0, 88, 3, -20, 19};
//   int main(void) {
//       printf("before: "); print_ints(nums, 8);
//       qsort(nums, 8, sizeof(int), cmp_int);
//       printf("after:  "); print_ints(nums, 8);
//       find(88);
//       find(5);
//       return 0;
//   }
//   void find(int key) {
//       int *p = bsearch(&key, nums, 8, sizeof(int), cmp_int);
//       if (p) printf("found %d at index %ld\n", *p, (long)(p - nums));
//       else   printf("%d is not in the array\n", key);
//   }

    .equ N, 8

    .text
    .global _main
    .p2align 2

// int cmp_int(const void *pa, const void *pb)
// qsort and bsearch call this. It only reads memory, calls nothing: a leaf.
cmp_int:
    ldr  w2, [x0]                   // a = *pa
    ldr  w3, [x1]                   // b = *pb
    cmp  w2, w3
    cset w0, gt                     // w0 = (a > b)
    cset w4, lt                     // w4 = (a < b)
    sub  w0, w0, w4                 // return (a > b) - (a < b)
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

// void find(int key) - bsearch for key and report the result
find:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str w0, [sp, #16]               // key lives in the frame: bsearch wants &key
    sub sp, sp, #16                 // room for printf's two variadic arguments
    add x0, x29, #16                // arg 1: &key (x29 still points at the frame)
    adrp x1, nums@PAGE              // arg 2: base
    add  x1, x1, nums@PAGEOFF
    mov  x2, #N                     // arg 3: count
    mov  x3, #4                     // arg 4: sizeof(int)
    adr  x4, cmp_int                // arg 5: the comparator
    bl   _bsearch                   // x0 = pointer to the match, or NULL
    cbz  x0, find_missing
    ldr  w9, [x0]                   // *p
    adrp x10, nums@PAGE
    add  x10, x10, nums@PAGEOFF
    sub  x10, x0, x10               // byte distance from the start...
    asr  x10, x10, #2               // ...divided by sizeof(int) = index
    stp  x9, x10, [sp]              // variadic: *p at [sp], index at [sp, #8]
    adrp x0, fmt_found@PAGE
    add  x0, x0, fmt_found@PAGEOFF
    bl   _printf
    b    find_done
find_missing:
    ldr  w9, [x29, #16]
    str  x9, [sp]
    adrp x0, fmt_missing@PAGE
    add  x0, x0, fmt_missing@PAGEOFF
    bl   _printf
find_done:
    add sp, sp, #16
    ldp x29, x30, [sp], #32
    ret

_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, str_before@PAGE
    add  x0, x0, str_before@PAGEOFF
    bl   _printf
    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #N
    bl   print_ints

    // qsort(nums, 8, sizeof(int), cmp_int)
    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #N
    mov  x2, #4
    adr  x3, cmp_int
    bl   _qsort

    adrp x0, str_after@PAGE
    add  x0, x0, str_after@PAGEOFF
    bl   _printf
    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #N
    bl   print_ints

    mov  w0, #88
    bl   find
    mov  w0, #5
    bl   find

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .data                           // qsort rearranges the array: it must be writable
    .p2align 2
nums: .word 42, -7, 19, 0, 88, 3, -20, 19

    .section __TEXT,__cstring
str_before:  .asciz "before: "
str_after:   .asciz "after:  "
fmt_first:   .asciz "%d"
fmt_next:    .asciz " %d"
fmt_found:   .asciz "found %d at index %ld\n"
fmt_missing: .asciz "%d is not in the array\n"
