// ex4.s - Exercise 15.4: the sum of an array, recursively (macOS).
//
// C:      long sum(long *a, long n) { return n == 0 ? 0 : a[0] + sum(a + 1, n - 1); }
//
// Build:  make
// Run:    ./ex4
// Expected output:
//   31
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    adrp x0, nums@PAGE
    add x0, x0, nums@PAGEOFF
    mov x1, #8
    bl sum
    bl print_uint
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x16, #1
    svc #0x80

// long sum(long *a, long n)
// Frame (32 bytes): x29, x30, x19 (a[0]), unused
sum:
    cbnz x1, sum_recurse
    mov x0, #0
    ret
sum_recurse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    ldr x19, [x0], #8           // x19 = a[0]; x0 = a + 1
    sub x1, x1, #1
    bl sum                      // sum(a + 1, n - 1)
    add x0, x19, x0
    ldr x19, [sp, #16]
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

    .data
nums:
    .quad 3, 1, 4, 1, 5, 9, 2, 6
