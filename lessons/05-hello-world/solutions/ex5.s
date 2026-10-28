// ex5.s - Exercise 05.5: normal output to stdout, an error to stderr, exit 3.
//
// Build:  make
// Run:    ./ex5; echo $?
//         ./ex5 2>/dev/null       (only the first line)
//         ./ex5 >/dev/null        (only the second line)
// Expected output:
//   working...           (stdout)
//   error: disk full     (stderr)
// Exit status (echo $?): 3

    .global _start

    .section .rodata
out:
    .ascii "working...\n"
    .equ out_len, . - out
err:
    .ascii "error: disk full\n"
    .equ err_len, . - err

    .text
    .p2align 2
_start:
    mov x0, #1                      // stdout
    adrp x1, out
    add x1, x1, :lo12:out
    mov x2, #out_len
    mov x8, #64
    svc #0

    mov x0, #2                      // stderr
    adrp x1, err
    add x1, x1, :lo12:err
    mov x2, #err_len
    mov x8, #64
    svc #0

    mov x0, #3                      // exit(3)
    mov x8, #93
    svc #0
