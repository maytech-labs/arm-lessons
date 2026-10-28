// ex8.s - Exercise 16.8: FizzBuzz from 1 to 15 with printf and puts.
//
// C version:
//     for (int i = 1; i <= 15; i++) {
//         if (i % 15 == 0)     puts("FizzBuzz");
//         else if (i % 3 == 0) puts("Fizz");
//         else if (i % 5 == 0) puts("Buzz");
//         else                 printf("%d\n", i);
//     }
//
// Build: make ex8
// Run:   ./ex8
// Expected output (one per line):
//     1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz

    .section .rodata
fmt_num:
    .asciz  "%d\n"
s_fizzbuzz:
    .asciz  "FizzBuzz"
s_fizz:
    .asciz  "Fizz"
s_buzz:
    .asciz  "Buzz"

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    mov     w19, #1                 // i
    mov     w20, #15                // the limit, and also the divisor 15
loop:
    cmp     w19, w20
    b.gt    done

    udiv    w9, w19, w20            // r = i % 15
    msub    w9, w9, w20, w19
    cbz     w9, say_fizzbuzz

    mov     w10, #3                 // r = i % 3
    udiv    w9, w19, w10
    msub    w9, w9, w10, w19
    cbz     w9, say_fizz

    mov     w10, #5                 // r = i % 5
    udiv    w9, w19, w10
    msub    w9, w9, w10, w19
    cbz     w9, say_buzz

    adrp    x0, fmt_num             // printf("%d\n", i)
    add     x0, x0, :lo12:fmt_num
    mov     w1, w19
    bl      printf
    b       next
say_fizzbuzz:
    adrp    x0, s_fizzbuzz
    add     x0, x0, :lo12:s_fizzbuzz
    b       say
say_fizz:
    adrp    x0, s_fizz
    add     x0, x0, :lo12:s_fizz
    b       say
say_buzz:
    adrp    x0, s_buzz
    add     x0, x0, :lo12:s_buzz
say:
    bl      puts
next:
    add     w19, w19, #1
    b       loop
done:
    mov     w0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
