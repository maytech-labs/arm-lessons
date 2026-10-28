// case.s - toupper and tolower with one bit, checked against the C library.
//
// 'A' = 0x41 = 0100 0001     'a' = 0x61 = 0110 0001
// Upper and lower case letters differ only in bit 5 (value 0x20).
//
// C version:
//     int my_toupper(int c) { return (c >= 'a' && c <= 'z') ? (c & ~0x20) : c; }
//     int my_tolower(int c) { return (c >= 'A' && c <= 'Z') ? (c | 0x20) : c; }
//     void str_upper(char *s) { for (; *s; s++) *s = my_toupper(*s); }
//     void str_lower(char *s) { for (; *s; s++) *s = my_tolower(*s); }
//
// Build: make case
// Run:   ./case
// Expected output:
//     Hello, World 42!
//     HELLO, WORLD 42!
//     hello, world 42!
//     mismatches with libc for 0..255: 0

    .data
text:
    .asciz  "Hello, World 42!"      // in .data, because we change it

    .section .rodata
fmt_mis:
    .asciz  "mismatches with libc for 0..255: %d\n"

    .text
    .p2align 2
// int my_toupper(int c)
my_toupper:
    sub     w1, w0, #'a'            // w1 = c - 'a'
    cmp     w1, #25                 // one unsigned compare checks both ends:
    b.hi    toupper_done            // c < 'a' wraps to a huge number
    and     w0, w0, #~0x20          // clear bit 5
toupper_done:
    ret

// int my_tolower(int c)
my_tolower:
    sub     w1, w0, #'A'
    cmp     w1, #25
    b.hi    tolower_done
    orr     w0, w0, #0x20           // set bit 5
tolower_done:
    ret

// void str_upper(char *s)
str_upper:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0
upper_loop:
    ldrb    w0, [x19]
    cbz     w0, upper_done
    bl      my_toupper
    strb    w0, [x19], #1           // store it back, move on
    b       upper_loop
upper_done:
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// void str_lower(char *s)
str_lower:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0
lower_loop:
    ldrb    w0, [x19]
    cbz     w0, lower_done
    bl      my_tolower
    strb    w0, [x19], #1
    b       lower_loop
lower_done:
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]

    adrp    x19, text
    add     x19, x19, :lo12:text
    mov     x0, x19
    bl      puts
    mov     x0, x19
    bl      str_upper
    mov     x0, x19
    bl      puts
    mov     x0, x19
    bl      str_lower
    mov     x0, x19
    bl      puts

    // Compare with libc for every byte value c = 0..255.
    mov     w19, #0                 // c
    mov     w20, #0                 // mismatches
cmp_loop:
    mov     w0, w19
    bl      my_toupper
    mov     w21, w0
    mov     w0, w19
    bl      toupper
    cmp     w0, w21
    cinc    w20, w20, ne            // count a mismatch
    mov     w0, w19
    bl      my_tolower
    mov     w21, w0
    mov     w0, w19
    bl      tolower
    cmp     w0, w21
    cinc    w20, w20, ne
    add     w19, w19, #1
    cmp     w19, #256
    b.lo    cmp_loop

    adrp    x0, fmt_mis
    add     x0, x0, :lo12:fmt_mis
    mov     w1, w20
    bl      printf

    mov     w0, #0
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
