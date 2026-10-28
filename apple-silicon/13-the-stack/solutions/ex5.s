// ex5.s - Exercise 13.5: read a line into a stack buffer, print it in uppercase (macOS).
//
// Build:  make
// Run:    echo 'Hello, World 42' | ./ex5
// Expected output:
//   HELLO, WORLD 42
// Exit status (echo $?): 0

    .global _main
    .text
    .p2align 2

_main:
    sub sp, sp, #128            // char buf[128]

    mov x0, #0
    mov x1, sp
    mov x2, #128
    mov x16, #3                 // n = read(0, buf, 128)
    svc #0x80
    mov x19, x0                 // x19 = n

    mov x9, #0                  // i = 0
loop:
    cmp x9, x19
    b.ge print                  // for (i = 0; i < n; i++)
    ldrb w10, [sp, x9]          // c = buf[i]
    sub w11, w10, #'a'
    cmp w11, #'z' - 'a'
    b.hi next                   // unsigned trick: c < 'a' or c > 'z' -> skip
    and w10, w10, #~0x20        // clear bit 5: 'a' (0x61) -> 'A' (0x41)
    strb w10, [sp, x9]
next:
    add x9, x9, #1
    b loop

print:
    cmp x19, #0
    b.le done
    mov x0, #1                  // write(1, buf, n)
    mov x1, sp
    mov x2, x19
    mov x16, #4
    svc #0x80
done:
    add sp, sp, #128
    mov x0, #0
    mov x16, #1
    svc #0x80
