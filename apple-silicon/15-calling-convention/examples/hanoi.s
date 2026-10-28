// hanoi.s - the Towers of Hanoi: recursion with four arguments (macOS).
//
// C:      void hanoi(long n, char from, char to, char via) {
//             if (n == 0) return;
//             hanoi(n - 1, from, via, to);
//             printf("%c->%c\n", from, to);
//             hanoi(n - 1, via, to, from);
//         }
//         hanoi(3, 'A', 'C', 'B');
//
// Build:  make
// Run:    ./hanoi
// Expected output (7 moves):
//   A->C
//   A->B
//   C->B
//   A->C
//   B->A
//   B->C
//   A->C
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #3
    mov x1, #'A'
    mov x2, #'C'
    mov x3, #'B'
    bl hanoi
    mov x0, #0
    mov x16, #1
    svc #0x80

// void hanoi(long n, char from, char to, char via)
//   All four values are needed after the first recursive call.
// Frame (48 bytes): x29, x30, then x19-x22
hanoi:
    cbz x0, hanoi_ret           // nothing to move: return without a frame
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0                 // n
    mov x20, x1                 // from
    mov x21, x2                 // to
    mov x22, x3                 // via

    sub x0, x19, #1             // hanoi(n - 1, from, via, to)
    mov x1, x20
    mov x2, x22
    mov x3, x21
    bl hanoi

    mov x0, x20                 // print "from->to\n"
    bl print_char
    mov x0, #'-'
    bl print_char
    mov x0, #'>'
    bl print_char
    mov x0, x21
    bl print_char
    mov x0, #'\n'
    bl print_char

    sub x0, x19, #1             // hanoi(n - 1, via, to, from)
    mov x1, x22
    mov x2, x21
    mov x3, x20
    bl hanoi

    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
hanoi_ret:
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
