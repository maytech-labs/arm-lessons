// ex8.s - a tiny stack machine whose instruction decoder is a jump table (lesson 24, exercise 24.8)
//
// Build: make ex8
// Run:   ./ex8
// Expected output:
//   35
//   100
//   -49
//
// Each instruction is one 8-byte word; PUSH is followed by its operand word.
//   0 HALT   stop, return 0
//   1 PUSH n push n
//   2 ADD    pop b, pop a, push a + b
//   3 SUB    pop b, pop a, push a - b
//   4 MUL    pop b, pop a, push a * b
//   5 PRINT  pop a, printf("%ld\n", a)
//   6 DUP    push a copy of the top
//   anything else: print "bad opcode N" and return 1
//
// The C version (core loop):
//   long stack[16]; long *top = stack;          // top points one past the last item
//   const long *pc = program;
//   for (;;) {
//       switch (*pc++) {
//       case 0: return 0;
//       case 1: *top++ = *pc++;                         break;
//       case 2: top--; top[-1] = top[-1] + top[0];      break;
//       case 3: top--; top[-1] = top[-1] - top[0];      break;
//       case 4: top--; top[-1] = top[-1] * top[0];      break;
//       case 5: printf("%ld\n", *--top);                break;
//       case 6: top[0] = top[-1]; top++;                break;
//       default: printf("bad opcode %ld\n", pc[-1]); return 1;
//       }
//   }

    .equ OP_HALT,  0
    .equ OP_PUSH,  1
    .equ OP_ADD,   2
    .equ OP_SUB,   3
    .equ OP_MUL,   4
    .equ OP_PRINT, 5
    .equ OP_DUP,   6
    .equ NOPS,     7

    .text
    .global main
    .p2align 2

// int run(const long *program)
// x19 = pc, x20 = top (both callee-saved: PRINT calls printf)
run:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    adrp x20, stack
    add  x20, x20, :lo12:stack
run_next:
    ldr  x9, [x19], #8              // opcode = *pc++
    cmp  x9, #NOPS
    b.hs run_bad
    adr  x10, run_table
    ldrsw x11, [x10, x9, lsl #2]
    add  x11, x10, x11
    br   x11
run_halt:
    mov  w0, #0
    b    run_return
run_push:
    ldr  x0, [x19], #8              // operand = *pc++
    str  x0, [x20], #8              // *top++ = operand
    b    run_next
run_add:
    ldp  x0, x1, [x20, #-16]!       // top -= 2; a = top[0], b = top[1]
    add  x0, x0, x1
    str  x0, [x20], #8              // push a + b
    b    run_next
run_sub:
    ldp  x0, x1, [x20, #-16]!
    sub  x0, x0, x1
    str  x0, [x20], #8
    b    run_next
run_mul:
    ldp  x0, x1, [x20, #-16]!
    mul  x0, x0, x1
    str  x0, [x20], #8
    b    run_next
run_print:
    ldr  x1, [x20, #-8]!            // pop
    adrp x0, fmt_num
    add  x0, x0, :lo12:fmt_num
    bl   printf
    b    run_next
run_dup:
    ldr  x0, [x20, #-8]
    str  x0, [x20], #8
    b    run_next
run_bad:
    mov  x1, x9
    adrp x0, fmt_bad
    add  x0, x0, :lo12:fmt_bad
    bl   printf
    mov  w0, #1
run_return:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .p2align 2
run_table:
    .word run_halt  - run_table
    .word run_push  - run_table
    .word run_add   - run_table
    .word run_sub   - run_table
    .word run_mul   - run_table
    .word run_print - run_table
    .word run_dup   - run_table

main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, program
    add  x0, x0, :lo12:program
    bl   run                        // run's return value is our exit status
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
    .p2align 3
program:
    .quad OP_PUSH, 2, OP_PUSH, 3, OP_ADD, OP_PUSH, 7, OP_MUL, OP_PRINT    // (2 + 3) * 7
    .quad OP_PUSH, 10, OP_DUP, OP_MUL, OP_PRINT                          // 10 * 10
    .quad OP_PUSH, 1, OP_PUSH, 50, OP_SUB, OP_PRINT                      // 1 - 50
    .quad OP_HALT
fmt_num: .asciz "%ld\n"
fmt_bad: .asciz "bad opcode %ld\n"

    .bss
    .p2align 3
stack: .space 16 * 8
