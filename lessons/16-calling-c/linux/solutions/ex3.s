// ex3.s - Exercise 16.3: a table of squares with printf.
//
// C version:
//     for (int i = 1; i <= 10; i++) printf("%d squared is %d\n", i, i * i);
//
// Build: make ex3
// Run:   ./ex3
// Expected output:
//     1 squared is 1
//     2 squared is 4
//     ...
//     10 squared is 100

    .section .rodata
fmt:
    .asciz  "%d squared is %d\n"

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]          // i lives in w19: it must survive printf

    mov     w19, #1
loop:
    cmp     w19, #10
    b.gt    done
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    mov     w1, w19                 // i
    mul     w2, w19, w19            // i * i
    bl      printf
    add     w19, w19, #1
    b       loop
done:
    mov     w0, #0
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
