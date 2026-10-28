// jump_table.s - a switch statement compiled to a jump table (lesson 24, macOS)
//
// Build: make jump_table
// Run:   ./jump_table
// Expected output:
//   calc(-1, 12, 4) = -1
//   calc(0, 12, 4) = 16
//   calc(1, 12, 4) = 8
//   calc(2, 12, 4) = 48
//   calc(3, 12, 4) = 3
//   calc(4, 12, 4) = -1
//
// The C version:
//   int calc(int op, int a, int b) {
//       switch (op) {
//       case 0:  return a + b;
//       case 1:  return a - b;
//       case 2:  return a * b;
//       case 3:  return a / b;
//       default: return -1;
//       }
//   }
//   int main(void) {
//       for (int op = -1; op < 5; op++)
//           printf("calc(%d, 12, 4) = %d\n", op, calc(op, 12, 4));
//       return 0;
//   }

    .equ NCASES, 4

    .text
    .global _main
    .p2align 2

// int calc(int op, int a, int b)
calc:
    cmp  w0, #NCASES
    b.hs calc_default               // unsigned >= 4: catches 4, 5, ... AND every negative op
    adr  x9, calc_table             // x9 = address of the table
    ldrsw x10, [x9, w0, uxtw #2]    // x10 = table[op] (a signed 32-bit offset)
    add  x10, x9, x10               // x10 = table + offset = address of the case
    br   x10                        // jump there (no return address: it is a goto)
calc_case0:
    add  w0, w1, w2
    ret
calc_case1:
    sub  w0, w1, w2
    ret
calc_case2:
    mul  w0, w1, w2
    ret
calc_case3:
    sdiv w0, w1, w2
    ret
calc_default:
    mov  w0, #-1
    ret

// One entry per case, in order. Each entry is "where the case is, measured
// from the start of the table", so the table needs no relocations.
    .p2align 2
calc_table:
    .word calc_case0 - calc_table
    .word calc_case1 - calc_table
    .word calc_case2 - calc_table
    .word calc_case3 - calc_table

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    sub sp, sp, #16                 // room for printf's two variadic arguments
    mov w19, #-1                    // op = -1
main_loop:
    cmp  w19, #5
    b.ge main_done
    mov  w0, w19
    mov  w1, #12
    mov  w2, #4
    bl   calc
    stp  x19, x0, [sp]              // printf(fmt, op, result): op at [sp], result at [sp, #8]
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
fmt: .asciz "calc(%d, 12, 4) = %d\n"
