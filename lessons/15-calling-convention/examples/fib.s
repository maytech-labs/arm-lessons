// fib.s - two recursive calls per call: the Fibonacci numbers.
//
// C:      long fib(long n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }
//         for (long i = 0; i <= 15; i++) print(fib(i));
//
// Build:  make
// Run:    ./fib
// Expected output:
//   0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    mov x19, #0
loop:
    mov x0, x19
    bl fib
    bl print_uint
    mov x0, #' '
    mov x1, #'\n'
    cmp x19, #15
    csel x0, x1, x0, eq
    bl print_char
    add x19, x19, #1
    cmp x19, #15
    b.le loop
    mov x0, #0
    mov x8, #93
    svc #0

// long fib(long n)
//   After the first call we need n (for the second call) and fib(n - 1)
//   (for the sum): two callee-saved registers.
// Frame (32 bytes): [sp] x29, [sp,#8] x30, [sp,#16] x19, [sp,#24] x20
fib:
    cmp x0, #2
    b.ge fib_recurse
    ret                         // fib(0) = 0, fib(1) = 1: n itself
fib_recurse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // x19 = n
    sub x0, x19, #1
    bl fib
    mov x20, x0                 // x20 = fib(n - 1)
    sub x0, x19, #2
    bl fib                      // x0 = fib(n - 2)
    add x0, x20, x0
    ldp x19, x20, [sp, #16]
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
