// stores.s - store 1, 2, 4 and 8 bytes into the same 8-byte variable.
//
// Build:  make
// Run:    ./stores; echo $?
// Expect: exit status 0xdd = 221. In the debugger, `x/8xb &target` after each
//         store shows exactly which bytes changed.

    .global _main

    .data
    .p2align 3
target:
    .quad 0                     // 8 zero bytes

    .text
    .p2align 2

_main:
    adrp x0, target@PAGE
    add x0, x0, target@PAGEOFF  // x0 = address of target
    movz x1, #0xaabb, lsl #48   // x1 = 0xaabbccdd11223344
    movk x1, #0xccdd, lsl #32
    movk x1, #0x1122, lsl #16
    movk x1, #0x3344
    str x1, [x0]                // 8 bytes: 44 33 22 11 dd cc bb aa
    mov w2, #0xeeff
    strh w2, [x0]               // 2 bytes: ff ee 22 11 dd cc bb aa
    mov w2, #0x99
    strb w2, [x0]               // 1 byte:  99 ee 22 11 dd cc bb aa
    mov w2, #0
    str w2, [x0]                // 4 bytes: 00 00 00 00 dd cc bb aa
    ldrb w0, [x0, #4]           // load the byte at target+4 (0xdd)
    mov x16, #1                 // 1 = exit
    svc #0x80
