// ex6.s - read a line, uppercase its letters, write it back.
//
// Build:  make
// Run:    echo 'Hello, World 42!' | ./ex6
// Expect: HELLO, WORLD 42!
//
// C equivalent:
//     char buf[256];
//     long n = read(0, buf, 256);
//     for (long i = 0; i < n; i++)
//         if (buf[i] >= 'a' && buf[i] <= 'z') buf[i] -= 32;
//     write(1, buf, n);

    .global _start

    .bss
buf:
    .space 256

    .text
    .p2align 2

_start:
    mov x0, #0                  // stdin
    adrp x1, buf
    add x1, x1, :lo12:buf
    mov x2, #256
    mov x8, #63                 // 63 = read
    svc #0
    mov x19, x0                 // x19 = n, bytes read

    adrp x1, buf
    add x1, x1, :lo12:buf       // x1 = p
    mov x2, x19                 // x2 = bytes left
loop:
    cbz x2, done
    ldrb w3, [x1]               // c = *p
    sub w4, w3, #'a'            // same unsigned trick as the digit test:
    cmp w4, #25                 // c - 'a' <= 25 (unsigned) means 'a'..'z'
    b.hi next
    sub w3, w3, #32             // to uppercase
    strb w3, [x1]               // *p = c
next:
    add x1, x1, #1              // p++
    sub x2, x2, #1
    b loop
done:
    mov x0, #1                  // stdout
    adrp x1, buf
    add x1, x1, :lo12:buf
    mov x2, x19                 // n bytes
    mov x8, #64                 // 64 = write
    svc #0

    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
