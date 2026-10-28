// lost_return.s - a broken program: outer calls inner but does not save x30, (macOS)
// so outer's ret returns to the wrong place.
//
// x19 counts how many times the end of outer runs. It should run once and the
// program should exit with 1. Instead outer's ret jumps back INTO outer,
// again and again; a safety check stops it at 3.
//
// Build:  make
// Run:    ./lost_return; echo $?
// Exit status (echo $?): 3     (the fixed version, fixed_return.s, exits with 1)

    .global _main
    .text
    .p2align 2

_main:
    mov x19, #0                 // counter
    bl outer                    // x30 = address of the mov below
    mov x0, x19                 // exit(counter)
    mov x16, #1
    svc #0x80

outer:
    bl inner                    // OVERWRITES x30 with the address of the add below
    add x19, x19, #1            // count how often we get here
    cmp x19, #3
    b.ge give_up                // safety net so the bug cannot loop forever
    ret                         // x30 still points at the add above: loops!
give_up:
    mov x0, x19
    mov x16, #1
    svc #0x80

inner:
    ret
