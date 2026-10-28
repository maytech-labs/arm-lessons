// dispatch_table.s - an array of function pointers, indexed and called (lesson 24, macOS)
//
// Build: make dispatch_table
// Run:   ./dispatch_table
// Expected output:
//   add(9, 4) = 13
//   sub(9, 4) = 5
//   mul(9, 4) = 36
//   max(9, 4) = 9
//
// The C version:
//   int add_ints(int a, int b) { return a + b; }
//   int sub_ints(int a, int b) { return a - b; }
//   int mul_ints(int a, int b) { return a * b; }
//   int max_ints(int a, int b) { return a > b ? a : b; }
//   int (*ops[4])(int, int) = {add_ints, sub_ints, mul_ints, max_ints};
//   const char *names[4]    = {"add", "sub", "mul", "max"};
//   int main(void) {
//       for (long i = 0; i < 4; i++)
//           printf("%s(9, 4) = %d\n", names[i], ops[i](9, 4));
//       return 0;
//   }

    .equ NOPS, 4

    .text
    .global _main
    .p2align 2

add_ints:
    add w0, w0, w1
    ret
sub_ints:
    sub w0, w0, w1
    ret
mul_ints:
    mul w0, w0, w1
    ret
max_ints:
    cmp  w0, w1
    csel w0, w0, w1, gt
    ret

_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    sub sp, sp, #16                 // room for printf's two variadic arguments
    adrp x20, ops@PAGE              // x20 = ops (array of 8-byte addresses)
    add  x20, x20, ops@PAGEOFF
    adrp x21, names@PAGE            // x21 = names (array of 8-byte pointers)
    add  x21, x21, names@PAGEOFF
    mov  x19, #0                    // i
main_loop:
    cmp  x19, #NOPS
    b.ge main_done
    ldr  x9, [x20, x19, lsl #3]     // x9 = ops[i]
    mov  w0, #9
    mov  w1, #4
    blr  x9                         // ops[i](9, 4)
    ldr  x9, [x21, x19, lsl #3]     // names[i]
    stp  x9, x0, [sp]               // variadic: name at [sp], result at [sp, #8]
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    bl   _printf
    add  x19, x19, #1
    b    main_loop
main_done:
    add sp, sp, #16
    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// Tables of absolute addresses go in .data: the program is loaded at a
// random address, so the loader must patch every entry at startup, and it
// can only write to writable sections.
    .data
    .p2align 3
ops:
    .quad add_ints
    .quad sub_ints
    .quad mul_ints
    .quad max_ints
names:
    .quad name_add
    .quad name_sub
    .quad name_mul
    .quad name_max

    .section __TEXT,__cstring
name_add: .asciz "add"
name_sub: .asciz "sub"
name_mul: .asciz "mul"
name_max: .asciz "max"
fmt:      .asciz "%s(9, 4) = %d\n"
