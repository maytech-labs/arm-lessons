// ex4.s - Exercise 07.4: build 0xdeadbeefcafef00d with movz and movk.
//
// Build:  make
// Run:    ./ex4; echo $?
// Expect: exit status 13 (0x0d). In gdb, p/x $x0 at the svc shows
//         0xdeadbeefcafef00d.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    movz x0, #0xf00d            // bits 0-15;  everything else becomes 0
    movk x0, #0xcafe, lsl #16   // bits 16-31; the rest is kept
    movk x0, #0xbeef, lsl #32   // bits 32-47
    movk x0, #0xdead, lsl #48   // bits 48-63
    mov x8, #93                 // 93 = exit
    svc #0                      // exit: the shell sees the low byte, 0x0d = 13
