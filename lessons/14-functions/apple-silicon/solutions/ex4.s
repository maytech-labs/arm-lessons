// ex4.s - Exercise 14.4: print 1..10, one per line, with print_uint and (macOS)
// a non-leaf print_line that calls both helpers.
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   1
//   2
//   ...
//   10
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    mov x19, #1
loop:
    mov x0, x19
    bl print_line               // print_line(i)
    add x19, x19, #1
    cmp x19, #10
    b.le loop
    mov x0, #0
    mov x16, #1
    svc #0x80

// void print_line(unsigned long n): print n then '\n'. Non-leaf.
print_line:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    bl print_uint
    mov x0, #'\n'
    bl print_char
    ldp x29, x30, [sp], #16
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
