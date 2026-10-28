// ex7.s - Exercise 27.7: unsigned 64-bit division by 10 without udiv.
//
//     unsigned long udiv10(unsigned long x) { return x / 10; }
//
// done the way the compiler does it: multiply by the magic number
// 0xcccccccccccccccd = ceil(2^67 / 10), keep the high 64 bits of the
// 128-bit product (umulh), and shift right by 3 more. Altogether that
// is (x * magic) >> 67.
//
// main checks udiv10(x) against udiv for every x from 0 to 9,999,999 and
// for a table of edge values near 2^64, 2^63 and 2^32.
// Build: make
// Run:   ./ex7
// Expected output:
//     ok

    .section .rodata
ok_msg:
    .asciz "ok"
bad_fmt:
    .asciz "mismatch at %lu: got %lu, want %lu\n"
    .p2align 3
edges:
    .quad 0xffffffffffffffff, 0xfffffffffffffffe, 0xfffffffffffffff6
    .quad 0xfffffffffffffff5, 0x8000000000000000, 0x7fffffffffffffff
    .quad 0x8000000000000009, 0x00000000ffffffff, 0x0000000100000000
    .quad 9999999999999999999, 10000000000000000000, 1844674407370955161
edges_end:

    .text

// unsigned long udiv10(unsigned long x): leaf, no frame.
    .global udiv10
    .type udiv10, %function
udiv10:
    mov x1, #0xcccd
    movk x1, #0xcccc, lsl #16
    movk x1, #0xcccc, lsl #32
    movk x1, #0xcccc, lsl #48   // x1 = 0xcccccccccccccccd
    umulh x0, x0, x1            // high 64 bits of x * magic
    lsr x0, x0, #3
    ret
    .size udiv10, .-udiv10

// int check(unsigned long x): returns 0 if udiv10 agrees with udiv,
// otherwise prints a message and returns 1.
// x19 = x, x20 = udiv10(x) (both needed after a call). Frame 32.
    .type check, %function
check:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    bl udiv10
    mov x20, x0
    mov x9, #10
    udiv x3, x19, x9            // the right answer
    mov w0, #0
    cmp x20, x3
    b.eq 1f
    mov x1, x19                 // printf(bad_fmt, x, got, want)
    mov x2, x20
    adrp x0, bad_fmt
    add x0, x0, :lo12:bad_fmt
    bl printf
    mov w0, #1
1:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
    .size check, .-check

// int main(void)
// x19 = loop value / pointer, x20 = limit / end, w21 = failures.
// All used after calls. Frame: 16 + 24 = 40, rounded up to 48.
    .global main
    .type main, %function
main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]

    mov w21, #0                 // failures = 0
    mov x19, #0                 // for (x = 0; x < 10000000; x++)
    movz x20, #0x9680
    movk x20, #0x98, lsl #16    // x20 = 10000000 = 0x989680
1:
    mov x0, x19
    bl check
    add w21, w21, w0
    add x19, x19, #1
    cmp x19, x20
    b.lo 1b

    adrp x19, edges             // for (p = edges; p < edges_end; p++)
    add x19, x19, :lo12:edges
    adrp x20, edges_end
    add x20, x20, :lo12:edges_end
2:
    ldr x0, [x19], #8
    bl check
    add w21, w21, w0
    cmp x19, x20
    b.lo 2b

    cbnz w21, 3f                // any failures: they were already printed
    adrp x0, ok_msg
    add x0, x0, :lo12:ok_msg
    bl puts
3:
    mov w0, w21                 // exit status = number of failures
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
    .size main, .-main
