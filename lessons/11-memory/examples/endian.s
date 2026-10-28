// endian.s - which byte of a 4-byte number sits at the lowest address?
//
// Build:  make
// Run:    ./endian; echo $?
// Expect: exit status 68 (0x44). AArch64 is little-endian: the least
//         significant byte of 0x11223344 is stored first.

    .global _start

    .data
    .p2align 2
number:
    .word 0x11223344

    .text
    .p2align 2

_start:
    adrp x0, number
    add x0, x0, :lo12:number    // x0 = address of number
    ldrb w1, [x0]               // the byte at the lowest address
    ldrb w2, [x0, #3]           // the byte at the highest address (0x11)
    mov x0, x1
    mov x8, #93                 // 93 = exit
    svc #0
