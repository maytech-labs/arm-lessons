// print_uint.s - the print-a-number block, finally as a function (macOS).
//
// C:      void print_uint(unsigned long n);   // prints n in decimal
//         void print_char(char c);
//         for (long i = 1; i <= 5; i++) {
//             print_uint(i * i);
//             print_char(i < 5 ? ' ' : '\n');
//         }
//
// Build:  make
// Run:    ./print_uint
// Expected output:
//   1 4 9 16 25
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    mov x19, #1                 // i = 1. Functions may change x0-x18; x19 is ours.
loop:
    mul x0, x19, x19
    bl print_uint               // print_uint(i * i)
    mov x0, #' '
    mov x1, #'\n'
    cmp x19, #5
    csel x0, x1, x0, eq
    bl print_char               // print_char(i < 5 ? ' ' : '\n')
    add x19, x19, #1
    cmp x19, #5
    b.le loop

    mov x0, #0
    mov x16, #1
    svc #0x80

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
