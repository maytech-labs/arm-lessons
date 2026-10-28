// modes.s - every addressing mode, used on one array of five longs.
//
// Build:  make
// Run:    ./modes; echo $?
// Expect: exit status 150 (10 + 20 + 30 + 40 + 50)
//
// C equivalent:
//     long a[5] = {10, 20, 30, 40, 50};
//     long sum = a[0] + a[1] + a[2] + a[3] + a[4];

    .global _start

    .data
    .p2align 3
a:  .quad 10, 20, 30, 40, 50    // 5 x 8 bytes = 40 bytes

    .text
    .p2align 2

_start:
    adrp x0, a
    add x0, x0, :lo12:a         // x0 = address of a[0]

    ldr x1, [x0]                // base:            a[0], address x0
    ldr x2, [x0, #8]            // base + offset:   a[1], address x0 + 8
    mov x9, #2
    ldr x3, [x0, x9, lsl #3]    // register offset: a[2], address x0 + (2 << 3)

    add x10, x0, #16            // x10 = address of a[2]
    ldr x4, [x10, #8]!          // pre-index:  x10 += 8 first, then load a[3]
                                //             (x10 now points at a[3])
    add x10, x10, #8            // x10 = address of a[4]
    ldr x5, [x10], #8           // post-index: load a[4] from x10, then x10 += 8
                                //             (x10 now points one past the end)

    add x0, x1, x2
    add x0, x0, x3
    add x0, x0, x4
    add x0, x0, x5              // 150
    mov x8, #93                 // 93 = exit
    svc #0
