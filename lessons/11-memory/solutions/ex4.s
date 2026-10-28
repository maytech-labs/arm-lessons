// ex4.s - swap two longs in memory, exit with the new value of x.
//
// Build:  make
// Run:    ./ex4; echo $?
// Expect: exit status 42
//
// C equivalent:
//     long x = 7, y = 42;
//     long t = x; x = y; y = t;
//     return x;

    .global _start

    .data
    .p2align 3
x:  .quad 7                     // x and y sit next to each other,
y:  .quad 42                    // so y is at x + 8

    .text
    .p2align 2

_start:
    adrp x0, x
    add x0, x0, :lo12:x         // x0 = &x (and &y = x0 + 8)

    // The long way: two loads, two stores.
    ldr x1, [x0]                // x1 = x
    ldr x2, [x0, #8]            // x2 = y
    str x2, [x0]                // x = old y
    str x1, [x0, #8]            // y = old x

    // The bonus way does the same in two instructions:
    //     ldp x1, x2, [x0]        // x1 = x, x2 = y
    //     stp x2, x1, [x0]        // x = old y, y = old x

    ldr x0, [x0]                // exit status = x
    mov x8, #93                 // 93 = exit
    svc #0
