// sp.s - look at the stack pointer. Its low 4 bits are always 0.
//
// Build:  make
// Run:    ./sp; echo $?
// Look:   gdb ./sp   then   starti   p/x $sp   x/4gx $sp
// Exit status (echo $?): 0     (sp & 15: sp is a multiple of 16)

    .global _start
    .text
    .p2align 2

_start:
    mov x1, sp                  // x1 = sp (you can copy sp like a register)
    and x0, x1, #15             // x0 = sp % 16
    mov x8, #93                 // exit(sp % 16)
    svc #0
