// sizes.s - load the same memory at four different sizes.
//
// Build:  make
// Run:    ./sizes; echo $?
// Expect: exit status 136 (0x88, the lowest byte). Look at x1-x4 in the
//         debugger to see the other three loads.

    .global _start

    .data
    .p2align 3
value:
    .quad 0x1122334455667788    // 8 bytes; in memory: 88 77 66 55 44 33 22 11

    .text
    .p2align 2

_start:
    adrp x0, value
    add x0, x0, :lo12:value     // x0 = address of value
    ldrb w1, [x0]               // 1 byte:  x1 = 0x88
    ldrh w2, [x0]               // 2 bytes: x2 = 0x7788
    ldr w3, [x0]                // 4 bytes: x3 = 0x55667788
    ldr x4, [x0]                // 8 bytes: x4 = 0x1122334455667788
    mov x0, x1                  // exit status = the byte we loaded
    mov x8, #93                 // 93 = exit
    svc #0
