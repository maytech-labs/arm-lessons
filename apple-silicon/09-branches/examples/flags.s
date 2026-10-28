// flags.s - watch the N Z C V flags change. Step through it in lldb (macOS).
//
// Build:  make
// Run:    ./flags; echo $?
// Expect: exit status 0. The interesting part is register read cpsr after each step:
//         after 1: Z C     after 2: N     after 3: N V     after 4: Z C

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #1                  // x1 = 1
    mov x2, #-1                 // x2 = -1 = 0xffffffffffffffff
    adds x0, x1, x2             // 1: 1 + (-1) = 0         -> Z=1, and C=1 (unsigned
                                //    0xfff...f + 1 carries out of bit 63)
    mov x3, #3                  // x3 = 3
    subs x0, x3, #5             // 2: 3 - 5 = -2           -> N=1, C=0 (it borrowed)
    mov w4, #0x7fffffff         // the largest 32-bit signed int
    adds w0, w4, #1             // 3: 0x7fffffff + 1 = 0x80000000
                                //    -> N=1, V=1 (signed overflow), C=0
    cmp x3, #3                  // 4: 3 - 3 = 0, result thrown away -> Z=1, C=1
    mov x0, #0                  // mov does not touch the flags
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0)
