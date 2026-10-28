// callback.s - for_each calls a function you pass in, once per element (lesson 24, macOS)
//
// Build: make callback
// Run:   ./callback
// Expected output:
//   [3][1][4][1][5]
//   [9][1][16][1][25]
//
// The C version:
//   void show(int x)        { printf("[%d]", x); }
//   void show_square(int x) { printf("[%d]", x * x); }
//   void for_each(const int *a, long n, void (*fn)(int)) {
//       for (long i = 0; i < n; i++)
//           fn(a[i]);
//   }
//   int nums[5] = {3, 1, 4, 1, 5};
//   int main(void) {
//       for_each(nums, 5, show);        putchar('\n');
//       for_each(nums, 5, show_square); putchar('\n');
//       return 0;
//   }

    .text
    .global _main
    .p2align 2

// void show(int x)
show:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16                 // room for printf's variadic argument
    str x0, [sp]                    // printf("[%d]", x): x goes on the stack
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    bl   _printf
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

// void show_square(int x)
show_square:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16
    mul w9, w0, w0                  // printf("[%d]", x * x)
    str x9, [sp]
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    bl   _printf
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

// void for_each(const int *a, long n, void (*fn)(int))
// fn is called many times, and each call may trash x0-x17, so a, n, fn and i
// all live in callee-saved registers.
for_each:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0                     // a
    mov x20, x1                     // n
    mov x21, x2                     // fn
    mov x22, #0                     // i = 0
for_each_loop:
    cmp x22, x20
    b.ge for_each_done              // i >= n: stop
    ldr w0, [x19, x22, lsl #2]      // argument: a[i]
    blr x21                         // fn(a[i])
    add x22, x22, #1
    b   for_each_loop
for_each_done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #5
    adr  x2, show                   // pass the function itself, not a call to it
    bl   for_each
    mov  w0, #'\n'
    bl   _putchar

    adrp x0, nums@PAGE
    add  x0, x0, nums@PAGEOFF
    mov  x1, #5
    adr  x2, show_square
    bl   for_each
    mov  w0, #'\n'
    bl   _putchar

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

    .section __TEXT,__const
    .p2align 2
nums: .word 3, 1, 4, 1, 5

    .section __TEXT,__cstring
fmt:  .asciz "[%d]"
