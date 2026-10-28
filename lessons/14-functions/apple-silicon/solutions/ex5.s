// ex5.s - Exercise 14.5: dist(a, b) = abs(a - b), a non-leaf calling a leaf (macOS).
//
// C:      long abs_(long x) { return x < 0 ? -x : x; }
//         long dist(long a, long b) { return abs_(a - b); }
//         ... print dist(3, 10), dist(10, 3), dist(-4, 4)
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   7 7 8
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #3
    mov x1, #10
    bl dist
    bl print_uint
    mov x0, #' '
    bl print_char

    mov x0, #10
    mov x1, #3
    bl dist
    bl print_uint
    mov x0, #' '
    bl print_char

    mov x0, #-4
    mov x1, #4
    bl dist
    bl print_uint
    mov x0, #'\n'
    bl print_char

    mov x0, #0
    mov x16, #1
    svc #0x80

// long dist(long a, long b): non-leaf
dist:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub x0, x0, x1              // a - b
    bl abs_
    ldp x29, x30, [sp], #16
    ret

// long abs_(long x): leaf. (Named abs_ to stay clear of C's abs in lesson 16.)
abs_:
    cmp x0, #0
    cneg x0, x0, lt
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
    mov x16, #4
    svc #0x80
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
    mov x16, #4
    svc #0x80
    add sp, sp, #16
    ret
