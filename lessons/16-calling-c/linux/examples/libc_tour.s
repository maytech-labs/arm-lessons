// libc_tour.s - strlen, printf, putchar and exit from assembly.
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

    .section .rodata
word:
    .asciz  "assembly"
fmt:
    .asciz  "\"%s\" has %ld characters\n"

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-32]!   // frame record + room for x19, x20
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // callee-saved: they survive our calls

    adrp    x19, word               // x19 = s (kept across calls)
    add     x19, x19, :lo12:word

    mov     x0, x19
    bl      strlen                  // x0 = strlen(s)
    mov     x20, x0                 // x20 = n (kept across calls)

    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    mov     x1, x19
    mov     x2, x20
    bl      printf

loop:                               // while (n > 0) putchar(s[--n]);
    cbz     x20, done
    sub     x20, x20, #1
    ldrb    w0, [x19, x20]          // the character, as an int argument
    bl      putchar
    b       loop
done:
    mov     w0, #'\n'
    bl      putchar

    mov     w0, #3
    bl      exit                    // exit flushes stdout, then ends the process
                                    // nothing after this runs: no epilogue needed
