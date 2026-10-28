// ex3.s - Exercise 16.3: a table of squares with printf (macOS).
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

    .section __TEXT,__cstring
fmt:
    .asciz  "%d squared is %d\n"

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]          // i lives in w19: it must survive printf
    sub     sp, sp, #16             // two variadic slots for printf

    mov     w19, #1
loop:
    cmp     w19, #10
    b.gt    done
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    mul     w9, w19, w19            // i * i (writing w9 zeroes its top half)
    stp     x19, x9, [sp]           // slot 0 = i, slot 1 = i * i
    bl      _printf
    add     w19, w19, #1
    b       loop
done:
    add     sp, sp, #16
    mov     w0, #0
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
