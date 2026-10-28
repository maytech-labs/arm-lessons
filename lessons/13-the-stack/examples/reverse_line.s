// reverse_line.s - read a line into a stack buffer and print it backwards.
//
// C:      char buf[64];
//         long n = read(0, buf, 64);
//         if (n > 0 && buf[n - 1] == '\n') n--;    // do not reverse the newline
//         for (long i = n - 1; i >= 0; i--) write(1, &buf[i], 1);
//         write(1, "\n", 1);
//
// Build:  make
// Run:    echo hello | ./reverse_line
// Expected output:
//   olleh
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    sub sp, sp, #64             // char buf[64]

    mov x0, #0                  // read(0, buf, 64)
    mov x1, sp
    mov x2, #64
    mov x8, #63
    svc #0
    mov x19, x0                 // x19 = n (bytes read)

    cmp x19, #0
    b.le print_newline          // nothing read
    sub x2, x19, #1
    ldrb w3, [sp, x2]           // buf[n - 1]
    cmp w3, #'\n'
    b.ne reverse
    mov x19, x2                 // drop the newline: n--

reverse:                        // x19 = how many characters are still to print
    cbz x19, print_newline
    sub x19, x19, #1            // i = n - 1, n - 2, ..., 0
    mov x0, #1
    add x1, sp, x19             // x1 = &buf[i]
    mov x2, #1
    mov x8, #64                 // write(1, &buf[i], 1)
    svc #0
    b reverse

print_newline:
    mov w3, #'\n'
    strb w3, [sp]               // reuse buf[0] to hold a newline
    mov x0, #1
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0

    add sp, sp, #64
    mov x0, #0
    mov x8, #93
    svc #0
