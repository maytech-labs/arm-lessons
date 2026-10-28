// ex6.s - Exercise 13.6: a local array of 10 longs on the stack.
//
// C:      long sq[10];
//         for (long i = 0; i < 10; i++) sq[i] = i * i;
//         long sum = 0;
//         for (long i = 0; i < 10; i++) sum += sq[i];
//         return sum;                         // 285
//
// Build:  make
// Run:    ./ex6; echo $?
// Exit status (echo $?): 29     (285 mod 256; check 285 in the debugger)

    .global _start
    .text
    .p2align 2

_start:
    sub sp, sp, #80             // long sq[10]: 80 bytes, a multiple of 16

    mov x9, #0                  // i = 0
fill:
    mul x10, x9, x9
    str x10, [sp, x9, lsl #3]   // sq[i] = i * i
    add x9, x9, #1
    cmp x9, #10
    b.lo fill

    mov x0, #0                  // sum = 0
    mov x9, #0
add_up:
    ldr x10, [sp, x9, lsl #3]
    add x0, x0, x10             // sum += sq[i]
    add x9, x9, #1
    cmp x9, #10
    b.lo add_up

    add sp, sp, #80
    mov x8, #93                 // exit(sum)
    svc #0
