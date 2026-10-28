// ex4.s - Exercise 07.4: build 0xdeadbeefcafef00d with movz and movk (macOS).
//
// Build:  make
// Run:    ./ex4; echo $?
// Expect: exit status 13 (0x0d). In lldb, register read x0 at the svc shows
//         0xdeadbeefcafef00d.

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    movz x0, #0xf00d            // bits 0-15;  everything else becomes 0
    movk x0, #0xcafe, lsl #16   // bits 16-31; the rest is kept
    movk x0, #0xbeef, lsl #32   // bits 32-47
    movk x0, #0xdead, lsl #48   // bits 48-63
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit: the shell sees the low byte, 0x0d = 13
