// wrap.s - the same addition in 32-bit (int) and 64-bit (long) registers (macOS).
//
// C:      unsigned int  a = 0xffffffff;  a = a + 1;   // wraps to 0
//         unsigned long b = 0xffffffff;  b = b + 1;   // 0x100000000
//         return a;
// Build:  make
// Run:    ./wrap; echo $?
// Expect: exit status 0. In lldb, x1 = 0x100000000.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov w0, #0xffffffff         // a = 0xffffffff (the largest 32-bit value)
    add w0, w0, #1              // a + 1 wraps to 0 in 32 bits
    mov x1, #0xffffffff         // b = 0xffffffff in a 64-bit register
    add x1, x1, #1              // b + 1 = 0x100000000: there is room for the carry
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(a) = exit(0)
