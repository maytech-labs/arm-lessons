// ex8.s - read two numbers from one line and print their sum.
//
// Build:  make
// Run:    echo '12 30' | ./ex8
// Expect: 42
//
// When the first parse loop stops on a non-digit, x1 already points one past
// that byte (the post-index load moved it), and x0 still counts it. So we step
// back one byte to look at it again while skipping spaces.

    .global _main

    .bss
inbuf:
    .space 64
numbuf:
    .space 32

    .text
    .p2align 2

_main:
    mov x0, #0                  // stdin
    adrp x1, inbuf@PAGE
    add x1, x1, inbuf@PAGEOFF
    mov x2, #64
    mov x16, #3                 // 3 = read
    svc #0x80                   // x0 = bytes read
    adrp x1, inbuf@PAGE         // reload the buffer address
    add x1, x1, inbuf@PAGEOFF
    mov x3, #10

    // ---- first number into x19 ----
    mov x19, #0
parse1:
    cbz x0, parsed1
    ldrb w2, [x1], #1
    sub w2, w2, #'0'
    cmp w2, #9
    b.hi parsed1_back           // stopped on a non-digit
    madd x19, x19, x3, x2
    sub x0, x0, #1
    b parse1
parsed1_back:
    sub x1, x1, #1              // un-read the non-digit
parsed1:

    // ---- skip spaces ----
skip:
    cbz x0, skipped
    ldrb w2, [x1]
    cmp w2, #' '
    b.ne skipped
    add x1, x1, #1
    sub x0, x0, #1
    b skip
skipped:

    // ---- second number into x20 ----
    mov x20, #0
parse2:
    cbz x0, parsed2
    ldrb w2, [x1], #1
    sub w2, w2, #'0'
    cmp w2, #9
    b.hi parsed2
    madd x20, x20, x3, x2
    sub x0, x0, #1
    b parse2
parsed2:

    add x19, x19, x20           // the sum

    // ---- print x19 in decimal, followed by a newline ----
    adrp x1, numbuf@PAGE
    add x1, x1, numbuf@PAGEOFF
    add x5, x1, #32
    mov x1, x5
    mov w2, #10
    strb w2, [x1, #-1]!
    mov x2, x19
    mov x3, #10
digit:
    udiv x4, x2, x3
    msub x6, x4, x3, x2
    add w6, w6, #'0'
    strb w6, [x1, #-1]!
    mov x2, x4
    cbnz x2, digit
    mov x0, #1
    sub x2, x5, x1
    mov x16, #4                 // 4 = write
    svc #0x80
    // ---- end of print ----

    mov x0, #0
    mov x16, #1                 // 1 = exit
    svc #0x80
