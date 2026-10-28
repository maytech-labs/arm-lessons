// ldrconst.s - the same constant with the ldr x0, =value pseudo-instruction.
//
// C:      unsigned long x = 0x1122334455667788;  return x & 0xff;
// Build:  make
// Run:    ./ldrconst; echo $?
// Expect: exit status 136 (0x88)
//
// ldr x0, =value is NOT a single "move" instruction. The assembler stores the
// 8-byte value in memory just after your code (a "literal pool") and emits a
// load from there. Loads are lesson 11; for now just know it exists.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    ldr x0, =0x1122334455667788 // x0 = the constant, loaded from the literal pool
    mov x8, #93                 // 93 = exit
    svc #0                      // exit with the low byte, 0x88
