// stack_buffer.s - print a number using a buffer on the stack instead of .bss.
//
// C:      char buf[32];                      // a local array
//         char *p = buf + 32;
//         *--p = '\n';
//         do { *--p = '0' + n % 10; n /= 10; } while (n);
//         write(1, p, buf + 32 - p);
//
// Build:  make
// Run:    ./stack_buffer
// Expected output:
//   9876543210
// Exit status (echo $?): 0

    .global _start
    .text
    .p2align 2

_start:
    sub sp, sp, #32             // char buf[32], at sp .. sp+31

    movz x19, #0x16ea           // n = 9876543210 = 0x24cb016ea
    movk x19, #0x4cb0, lsl #16
    movk x19, #0x2, lsl #32

    add x5, sp, #32             // x5 = buf + 32 (one past the end)
    mov x1, x5                  // x1 = p
    mov w6, #'\n'
    strb w6, [x1, #-1]!         // *--p = '\n'
    mov x3, #10
digit:
    udiv x4, x19, x3            // x4 = n / 10
    msub x6, x4, x3, x19        // x6 = n % 10
    add w6, w6, #'0'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x19, x4                 // n /= 10
    cbnz x19, digit

    mov x0, #1                  // write(1, p, end - p)
    sub x2, x5, x1
    mov x8, #64
    svc #0

    add sp, sp, #32             // free buf
    mov x0, #0
    mov x8, #93
    svc #0
