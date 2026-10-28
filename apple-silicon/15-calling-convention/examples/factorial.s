// factorial.s - recursion: a function that calls itself (macOS).
//
// C:      unsigned long fact(unsigned long n) {
//             if (n <= 1) return 1;
//             return n * fact(n - 1);
//         }
//         print(fact(20));
//
// Build:  make
// Run:    ./factorial
// Debug:  lldb ./factorial   breakpoint set -n fact -c '$x0 == 1'   run   bt
// Expected output:
//   2432902008176640000
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #20
    bl fact
    bl print_uint
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x16, #1
    svc #0x80

// unsigned long fact(unsigned long n)
//   Needs n after the recursive call, so n lives in x19 (saved in the frame).
// Frame (32 bytes): [sp] x29, [sp,#8] x30, [sp,#16] caller's x19
fact:
    cmp x0, #1
    b.hi fact_recurse           // n > 1: recursive case
    mov x0, #1                  // base case: no frame needed, we call nothing
    ret
fact_recurse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]          // save the caller's x19 (maybe an outer fact's n)
    mov x19, x0                 // x19 = n
    sub x0, x0, #1
    bl fact                     // x0 = fact(n - 1)
    mul x0, x19, x0             // n * fact(n - 1)
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
