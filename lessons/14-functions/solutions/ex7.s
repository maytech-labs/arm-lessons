// ex7.s - Exercise 14.7: a table of n, n^2, n^3 for n = 1..5.
//
// Build:  make
// Run:    ./ex7
// Expected output:
//   1 1 1
//   2 4 8
//   3 9 27
//   4 16 64
//   5 25 125
// Exit status (echo $?): 0
//
// print_row(n) is non-leaf and needs n after several calls, so it keeps n in
// its frame.

    .global _start
    .text
    .p2align 2

_start:
    mov x19, #1
loop:
    mov x0, x19
    bl print_row
    add x19, x19, #1
    cmp x19, #5
    b.le loop
    mov x0, #0
    mov x8, #93
    svc #0

// void print_row(long n)
// Frame: [sp] x29, [sp, #8] x30, [sp, #16] n
print_row:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x0, [sp, #16]           // keep n

    bl print_uint               // n
    mov x0, #' '
    bl print_char

    ldr x0, [sp, #16]
    mul x0, x0, x0
    bl print_uint               // n^2
    mov x0, #' '
    bl print_char

    ldr x1, [sp, #16]
    mul x0, x1, x1
    mul x0, x0, x1
    bl print_uint               // n^3
    mov x0, #'\n'
    bl print_char

    ldp x29, x30, [sp], #32
    ret

// void print_uint(unsigned long n)
//   in:  x0 = n
//   Leaf function (it makes a system call, but calls no function), so it
//   does not save x30. Uses a 32-byte buffer on the stack.
print_uint:
    sub sp, sp, #32             // char buf[32]
    add x5, sp, #32             // x5 = end of buf
    mov x1, x5                  // x1 = p
    mov x3, #10
print_uint_digit:
    udiv x4, x0, x3             // x4 = n / 10
    msub x6, x4, x3, x0         // x6 = n % 10
    add w6, w6, #'0'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x0, x4                  // n /= 10
    cbnz x0, print_uint_digit
    mov x0, #1                  // write(1, p, end - p)
    sub x2, x5, x1
    mov x8, #64
    svc #0
    add sp, sp, #32
    ret

// void print_char(char c)
//   in:  w0 = c
print_char:
    sub sp, sp, #16             // a 1-byte buffer, but sp moves by 16
    strb w0, [sp]
    mov x0, #1                  // write(1, &c, 1)
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0
    add sp, sp, #16
    ret
