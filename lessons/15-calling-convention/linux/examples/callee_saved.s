// callee_saved.s - a function that uses x19 and x20 must save and restore them.
//
// C:      long sum_of_squares(long *a, long n);   // uses two long-lived values
//         _start keeps its own counter in x19 across the calls.
//
// Build:  make
// Run:    ./callee_saved
// Expected output:
//   14 14 14
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    mov x19, #3                 // our counter: must survive every call
again:
    adrp x0, nums
    add x0, x0, :lo12:nums
    mov x1, #3
    bl sum_of_squares           // 1 + 4 + 9 = 14
    bl print_uint
    mov x0, #' '
    mov x1, #'\n'
    cmp x19, #1
    csel x0, x1, x0, eq
    bl print_char
    subs x19, x19, #1           // still our value, because every function
    b.ne again                  // we called preserved x19

    mov x0, #0
    mov x8, #93
    svc #0

// long sum_of_squares(long *a, long n)
//   Keeps the pointer in x19 and the count in x20 across calls to square.
//   x19 and x20 are callee-saved: we must give the caller back its values.
// Frame (48 bytes): [sp] x29, [sp,#8] x30, [sp,#16] x19, [sp,#24] x20,
//                   [sp,#32] x21, [sp,#40] unused (keeps the size a multiple of 16)
sum_of_squares:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]     // save the CALLER's x19 and x20
    str x21, [sp, #32]          // and x21 (the running total)

    mov x19, x0                 // p
    mov x20, x1                 // n
    mov x21, #0                 // total
sum_of_squares_loop:
    cbz x20, sum_of_squares_done
    ldr x0, [x19], #8           // x0 = *p++
    bl square                   // square may change x0-x18, not x19-x21
    add x21, x21, x0
    sub x20, x20, #1
    b sum_of_squares_loop
sum_of_squares_done:
    mov x0, x21

    ldr x21, [sp, #32]          // restore in reverse
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// long square(long n): leaf
square:
    mul x0, x0, x0
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

    .data
nums:
    .quad 1, 2, 3
