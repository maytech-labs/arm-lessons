// map_filter.s - your own generic map and filter, driven by function pointers (lesson 24, macOS)
//
// Build: make map_filter
// Run:   ./map_filter
// Expected output:
//   start:   1 2 3 4 5 6 7 8 9 10
//   odd:     1 3 5 7 9
//   squared: 1 9 25 49 81
//
// The C version:
//   void map(int *a, long n, int (*f)(int)) {
//       for (long i = 0; i < n; i++) a[i] = f(a[i]);
//   }
//   long filter(const int *src, long n, int *dst, int (*keep)(int)) {
//       long k = 0;
//       for (long i = 0; i < n; i++)
//           if (keep(src[i])) dst[k++] = src[i];
//       return k;
//   }
//   int is_odd(int x) { return x & 1; }
//   int square(int x) { return x * x; }
//   int nums[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
//   int out[10];
//   int main(void) {
//       printf("start:   "); print_ints(nums, 10);
//       long k = filter(nums, 10, out, is_odd);
//       printf("odd:     "); print_ints(out, k);
//       map(out, k, square);
//       printf("squared: "); print_ints(out, k);
//       return 0;
//   }

    .text
    .global _main
    .p2align 2

// int is_odd(int x)
is_odd:
    and w0, w0, #1
    ret

// int square(int x)
square:
    mul w0, w0, w0
    ret

// void map(int *a, long n, int (*f)(int))
map:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0                     // a
    mov x20, x1                     // n
    mov x21, x2                     // f
    mov x22, #0                     // i
map_loop:
    cmp x22, x20
    b.ge map_done
    ldr w0, [x19, x22, lsl #2]      // f(a[i])
    blr x21
    str w0, [x19, x22, lsl #2]      // a[i] = result
    add x22, x22, #1
    b   map_loop
map_done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// long filter(const int *src, long n, int *dst, int (*keep)(int))
filter:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    mov x19, x0                     // src
    mov x20, x1                     // n
    mov x21, x2                     // dst
    mov x22, x3                     // keep
    mov x23, #0                     // i
    mov x24, #0                     // k
filter_loop:
    cmp x23, x20
    b.ge filter_done
    ldr w0, [x19, x23, lsl #2]
    blr x22                         // keep(src[i])
    cbz w0, filter_next             // 0 means "drop it"
    ldr w9, [x19, x23, lsl #2]      // reload src[i]: the call may have trashed w9
    str w9, [x21, x24, lsl #2]      // dst[k] = src[i]
    add x24, x24, #1                // k++
filter_next:
    add x23, x23, #1
    b   filter_loop
filter_done:
    mov x0, x24                     // return k
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
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
    str x19, [sp, #16]              // x19 = k

    adrp x0, str_start@PAGE
    add  x0, x0, str_start@PAGEOFF
    bl   _printf
    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #10
    bl   print_ints

    // k = filter(nums, 10, out, is_odd)
    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #10
    adrp x2, out@PAGE
    add  x2, x2, out@PAGEOFF
    adr  x3, is_odd
    bl   filter
    mov  x19, x0

    adrp x0, str_odd@PAGE
    add  x0, x0, str_odd@PAGEOFF
    bl   _printf
    adrp x0, out@PAGE
    add  x0, x0, out@PAGEOFF
    mov  x1, x19
    bl   print_ints

    // map(out, k, square)
    adrp x0, out@PAGE
    add  x0, x0, out@PAGEOFF
    mov  x1, x19
    adr  x2, square
    bl   map

    adrp x0, str_squared@PAGE
    add  x0, x0, str_squared@PAGEOFF
    bl   _printf
    adrp x0, out@PAGE
    add  x0, x0, out@PAGEOFF
    mov  x1, x19
    bl   print_ints

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__const
    .p2align 2
nums:        .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

    .section __TEXT,__cstring
str_start:   .asciz "start:   "
str_odd:     .asciz "odd:     "
str_squared: .asciz "squared: "
fmt_first:   .asciz "%d"
fmt_next:    .asciz " %d"

    .bss
    .p2align 2
out: .space 10 * 4
