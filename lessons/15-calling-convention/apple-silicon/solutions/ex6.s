// ex6.s - Exercise 15.6: clobber_bug.s with bad_helper fixed (macOS).
//
// Build:  make
// Run:    ./ex6; echo $?
// Exit status (echo $?): 3

    .global _main
    .text
    .p2align 2

_main:
    mov x19, #3
    mov x20, #0
again:
    bl good_helper
    add x20, x20, #1
    subs x19, x19, #1
    b.gt again
    mov x0, x20
    mov x16, #1
    svc #0x80

// Fix 1 (best): a temporary belongs in a caller-saved register, x9-x15.
good_helper:
    mov x9, #1
    add x0, x9, #1
    ret

// Fix 2: if it really must be x19, save and restore it. (Not called; shown
// for comparison.)
good_helper_2:
    str x19, [sp, #-16]!
    mov x19, #1
    add x0, x19, #1
    ldr x19, [sp], #16
    ret
