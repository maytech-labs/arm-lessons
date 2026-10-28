// ex6.s - a switch with gaps and shared cases, as a jump table (lesson 24, exercise 24.6, macOS)
//
// Build: make ex6
// Run:   ./ex6
// Expected output:
//   f(-1) = 99
//   f(0) = 99
//   f(1) = 10
//   f(2) = 102
//   f(3) = -3
//   f(4) = -4
//   f(5) = 99
//   f(6) = 0
//   f(7) = 99
//
// The C version:
//   int f(int x) {
//       switch (x) {
//       case 1:  return x * 10;
//       case 2:  return x + 100;
//       case 3:
//       case 4:  return -x;
//       case 6:  return 0;
//       default: return 99;
//       }
//   }
//   int main(void) {
//       for (int x = -1; x <= 7; x++) printf("f(%d) = %d\n", x, f(x));
//   }

    .text
    .global _main
    .p2align 2

f:
    cmp  w0, #7                     // the table covers 0..6
    b.hs f_default
    adr  x9, f_table
    ldrsw x10, [x9, w0, uxtw #2]
    add  x10, x9, x10
    br   x10
f_case1:
    mov  w1, #10
    mul  w0, w0, w1
    ret
f_case2:
    add  w0, w0, #100
    ret
f_case3_4:
    neg  w0, w0
    ret
f_case6:
    mov  w0, #0
    ret
f_default:
    mov  w0, #99
    ret

    .p2align 2
f_table:
    .word f_default - f_table       // 0: no case 0, so default
    .word f_case1   - f_table       // 1
    .word f_case2   - f_table       // 2
    .word f_case3_4 - f_table       // 3 } two labels, one body:
    .word f_case3_4 - f_table       // 4 } two entries, same target
    .word f_default - f_table       // 5: a gap
    .word f_case6   - f_table       // 6

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    sub sp, sp, #16                 // room for printf's variadic arguments
    mov w19, #-1
main_loop:
    cmp  w19, #7
    b.gt main_done
    mov  w0, w19
    bl   f
    stp  x19, x0, [sp]              // x at [sp], f(x) at [sp, #8]
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    bl   _printf
    add  w19, w19, #1
    b    main_loop
main_done:
    add sp, sp, #16
    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt: .asciz "f(%d) = %d\n"
