// clobber_bug.s - a broken program: bad_helper uses x19 without saving it.
//
// _start expects to loop 3 times (exit 3). bad_helper sets x19 to 0 as
// scratch, which ends _start's loop after the first pass.
//
// Build:  make
// Run:    ./clobber_bug; echo $?
// Exit status (echo $?): 1     (should be 3)

    .global _start
    .text
    .p2align 2

_start:
    mov x19, #3                 // loop counter, callee-saved
    mov x20, #0                 // passes completed
again:
    bl bad_helper
    add x20, x20, #1
    subs x19, x19, #1
    b.gt again                  // signed: stop at 0 or below
    mov x0, x20                 // exit(passes)
    mov x8, #93
    svc #0

// BROKEN: uses x19 but never saves or restores it.
bad_helper:
    mov x19, #1                 // "just a temporary"... but it belongs to the caller
    add x0, x19, #1
    ret
