// align.s - see where .p2align puts things. Run `nm -n align` to read the
//           addresses of the labels.
//
// Build:  make
// Run:    ./align; echo $?
// Expect: exit status 0. `nm -n align` shows `aligned` at an address
//         that is a multiple of 8, and `after` exactly 1 byte after `one`.

    .global _start

    .data
one:
    .byte 1                     // 1 byte: the next free address is odd
after:
    .byte 2                     // lands right after, wherever that is
    .p2align 3                  // skip ahead to the next multiple of 8 (2^3)
aligned:
    .quad 3                     // an 8-byte value on an 8-byte boundary

    .text
    .p2align 2

_start:
    mov x0, #0
    mov x8, #93                 // 93 = exit
    svc #0
