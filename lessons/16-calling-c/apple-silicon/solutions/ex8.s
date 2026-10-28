// ex8.s - Exercise 16.8: FizzBuzz from 1 to 15 with printf and puts (macOS).
//
// Build: make ex8
// Run:   ./ex8
// Expected output (one per line):
//     1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz

    .section __TEXT,__cstring
fmt_num:
    .asciz  "%d\n"
s_fizzbuzz:
    .asciz  "FizzBuzz"
s_fizz:
    .asciz  "Fizz"
s_buzz:
    .asciz  "Buzz"

    .text
    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    sub     sp, sp, #16             // one variadic slot (rounded up to 16)

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

    adrp    x0, fmt_num@PAGE        // printf("%d\n", i)
    add     x0, x0, fmt_num@PAGEOFF
    str     x19, [sp]               // slot 0 = i
    bl      _printf
    b       next
say_fizzbuzz:
    adrp    x0, s_fizzbuzz@PAGE
    add     x0, x0, s_fizzbuzz@PAGEOFF
    b       say
say_fizz:
    adrp    x0, s_fizz@PAGE
    add     x0, x0, s_fizz@PAGEOFF
    b       say
say_buzz:
    adrp    x0, s_buzz@PAGE
    add     x0, x0, s_buzz@PAGEOFF
say:
    bl      _puts
next:
    add     w19, w19, #1
    b       loop
done:
    add     sp, sp, #16
    mov     w0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
