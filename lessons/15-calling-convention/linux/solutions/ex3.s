// ex3.s - Exercise 15.3: recursive power(base, exp).
//
// C:      long power(long b, long e) { return e == 0 ? 1 : b * power(b, e - 1); }
//
// Build:  make
// Run:    ./ex3
// Expected output:
//   59049
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #3
    mov x1, #10
    bl power                    // 3^10
    bl print_uint
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x8, #93
    svc #0

// long power(long b, long e)
// Frame (32 bytes): x29, x30, x19 (b), unused
power:
    cbnz x1, power_recurse
    mov x0, #1
    ret
power_recurse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                 // b, needed after the call
    sub x1, x1, #1
    bl power                    // x0 = power(b, e - 1); x0 is still b on entry
    mul x0, x19, x0
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
