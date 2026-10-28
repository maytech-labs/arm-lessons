// buffering.s - stdio buffers output; a raw write does not wait (lesson 25)
//
// Build: make buffering
// Run:   ./buffering
// Expected output (on a terminal and through a pipe alike):
//   B
//   AC
//
// C version:
//   int main(void) {
//       printf("A");             // goes into stdout's buffer, not to the screen yet
//       write(1, "B\n", 2);      // system call: goes out immediately
//       printf("C\n");           // more buffer
//       return 0;                // returning from main flushes stdout: "AC\n" appears
//   }

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, str_a
    add x0, x0, :lo12:str_a
    bl printf                   // printf("A")

    mov x0, #1                  // write(1, "B\n", 2): the raw system call
    adrp x1, str_b
    add x1, x1, :lo12:str_b
    mov x2, #2
    mov x8, #64
    svc #0

    adrp x0, str_c
    add x0, x0, :lo12:str_c
    bl printf                   // printf("C\n")

    mov w0, #0                  // return 0: libc's exit() flushes stdout
    ldp x29, x30, [sp], #16
    ret

    .section .rodata
str_a: .asciz "A"
str_b: .ascii "B\n"
str_c: .asciz "C\n"
