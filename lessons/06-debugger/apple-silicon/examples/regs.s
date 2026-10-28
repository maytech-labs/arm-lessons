// regs.s - a few register moves to watch in the debugger.
//
// Build:  make
// Run:    ./regs; echo $?
// Expect: exit status 42 (nothing is printed)
//
// Step through it with:  lldb ./regs   then   b main, run, and si

    .global _main               // make _main visible to the linker
    .text                       // code goes in the text section
    .p2align 2                  // instructions are 4 bytes: align to 2^2

_main:
    mov x0, #1                  // x0 = 1
    mov x1, #2                  // x1 = 2
    mov x2, #0xff               // x2 = 255
    mov x3, x2                  // x3 = x2 (copy, x2 keeps its value)
    mov w4, #7                  // w4 = 7 (and the top half of x4 becomes 0)
    mov x0, #42                 // x0 = 42, the exit status
    mov x16, #1                 // 1 = exit
    svc #0x80                   // call the kernel: exit(42)
