// ex5.s - Exercise 15.5: nine arguments.
//
// C:      long weighted(long a1, ..., long a9) { return 1*a1 + 2*a2 + ... + 9*a9; }
//         print(weighted(1, 2, 3, 4, 5, 6, 7, 8, 9));      // 1 + 4 + ... + 81
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   285
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #1
    mov x1, #2
    mov x2, #3
    mov x3, #4
    mov x4, #5
    mov x5, #6
    mov x6, #7
    mov x7, #8
    mov x9, #9
    str x9, [sp, #-16]!         // the 9th argument at [sp]; 16 bytes keeps alignment
    bl weighted
    add sp, sp, #16
    bl print_uint
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x8, #93
    svc #0

// long weighted(a1..a8 in x0-x7, a9 at [sp])
weighted:
    mov x9, #2
    madd x0, x1, x9, x0         // a1 + 2*a2
    mov x9, #3
    madd x0, x2, x9, x0
    mov x9, #4
    madd x0, x3, x9, x0
    mov x9, #5
    madd x0, x4, x9, x0
    mov x9, #6
    madd x0, x5, x9, x0
    mov x9, #7
    madd x0, x6, x9, x0
    mov x9, #8
    madd x0, x7, x9, x0
    ldr x10, [sp]               // a9
    mov x9, #9
    madd x0, x10, x9, x0
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
