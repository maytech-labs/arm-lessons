// ex7.s - Exercise 15.7: print a number recursively, no buffer (macOS).
//
// C:      void print_rec(unsigned long n) {
//             if (n >= 10) print_rec(n / 10);   // print the leading digits first
//             print_char('0' + n % 10);         // then the last one
//         }
//
// Build:  make
// Run:    ./ex7
// Expected output:
//   9876543210 0 7
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    movz x0, #0x16ea            // 9876543210
    movk x0, #0x4cb0, lsl #16
    movk x0, #0x2, lsl #32
    bl print_rec
    mov x0, #' '
    bl print_char
    mov x0, #0
    bl print_rec
    mov x0, #' '
    bl print_char
    mov x0, #7
    bl print_rec
    mov x0, #'\n'
    bl print_char
    mov x0, #0
    mov x16, #1
    svc #0x80

// void print_rec(unsigned long n)
// Frame (32 bytes): x29, x30, x19 (n), unused
print_rec:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    cmp x19, #10
    b.lo print_rec_last
    mov x1, #10
    udiv x0, x19, x1
    bl print_rec                // print_rec(n / 10)
print_rec_last:
    mov x1, #10
    udiv x2, x19, x1
    msub x0, x2, x1, x19        // n % 10
    add x0, x0, #'0'
    bl print_char
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
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
