// libc_tour.s - strlen, printf, putchar and exit from assembly (macOS).
//
// C version:
//     int main(void) {
//         const char *s = "assembly";
//         long n = strlen(s);
//         printf("\"%s\" has %ld characters\n", s, n);
//         for (int i = 0; i < n; i++) {   // print it backwards
//             putchar(s[n - 1 - i]);
//         }
//         putchar('\n');
//         exit(3);                        // never returns
//     }
//
// Build: make libc_tour
// Run:   ./libc_tour; echo $?
// Expected output:
//     "assembly" has 8 characters
//     ylbmessa
// Expected exit status: 3

    .section __TEXT,__cstring
word:
    .asciz  "assembly"
fmt:
    .asciz  "\"%s\" has %ld characters\n"

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-32]!   // frame record + room for x19, x20
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // callee-saved: they survive our calls

    adrp    x19, word@PAGE          // x19 = s (kept across calls)
    add     x19, x19, word@PAGEOFF

    mov     x0, x19
    bl      _strlen                 // not variadic: argument in x0 as usual
    mov     x20, x0                 // x20 = n (kept across calls)

    sub     sp, sp, #16             // printf is variadic: 2 slots on the stack
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    stp     x19, x20, [sp]          // slot 0 = s, slot 1 = n
    bl      _printf
    add     sp, sp, #16

loop:                               // while (n > 0) putchar(s[--n]);
    cbz     x20, done
    sub     x20, x20, #1
    ldrb    w0, [x19, x20]          // putchar is not variadic: w0
    bl      _putchar
    b       loop
done:
    mov     w0, #'\n'
    bl      _putchar

    mov     w0, #3
    bl      _exit                   // flushes stdout, ends the process
