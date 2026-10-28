// ex8.s - Exercise 15.8: sum 1..n with tail recursion and an accumulator,
// for n = 1000000. The plain recursive version overflows the stack.
//
// C:      unsigned long sum_to(unsigned long n, unsigned long acc) {
//             if (n == 0) return acc;
//             return sum_to(n - 1, acc + n);    // a tail call
//         }
//
// Build:  make
// Run:    ./ex8
// Expected output:
//   500000500000
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    movz x0, #0x4240            // n = 1000000 = 0xf4240
    movk x0, #0xf, lsl #16
    mov x1, #0                  // acc = 0
    bl sum_to
    bl print_uint
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x8, #93
    svc #0

// unsigned long sum_to(unsigned long n, unsigned long acc): no frame at all
sum_to:
    cbz x0, sum_to_done
    add x1, x1, x0              // acc + n
    sub x0, x0, #1              // n - 1
    b sum_to                    // tail call
sum_to_done:
    mov x0, x1
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
