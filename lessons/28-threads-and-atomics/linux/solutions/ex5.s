// ex5.s - Exercise 28.5: an atomic maximum built from ldxr/stxr.
// atomic_max(&best, v) sets best = v only if v is bigger, safely even when
// several threads call it at once. Thread t (t = 0..3) handles
// i = t, t+4, t+8, ... below 1000000 and calls atomic_max(&best, value(i))
// where value(i) = (i * 7919) % 1000003.
//
// Build: make ex5
// Run:   ./ex5
// Expected output, every time:
//     max = 1000002

    .equ NTHREADS, 4

    .text
    .global main

// void atomic_max(long *p, long v)
atomic_max:
am_retry:
    ldxr    x2, [x0]                // current value, and start watching *p
    cmp     x2, x1
    b.ge    am_keep                 // current >= v: nothing to store
    stxr    w3, x1, [x0]            // try *p = v
    cbnz    w3, am_retry            // somebody changed *p: look again
    ret
am_keep:
    clrex                           // we decided not to store: drop the watch
    ret

// void *worker(void *arg): arg is the thread number t, passed as the pointer.
worker:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    mov     x19, x0                 // i = t
    movz    x20, #0x4240            // limit = 1000000
    movk    x20, #0xf, lsl #16
    movz    x21, #0x4243            // modulus = 1000003 = 0xf4243
    movk    x21, #0xf, lsl #16
    adrp    x22, best
    add     x22, x22, :lo12:best
w_loop:
    cmp     x19, x20
    b.hs    w_done
    mov     x9, #7919
    mul     x9, x19, x9             // i * 7919
    udiv    x10, x9, x21
    msub    x1, x10, x21, x9        // value = (i * 7919) % 1000003
    mov     x0, x22
    bl      atomic_max
    add     x19, x19, #NTHREADS     // i += 4
    b       w_loop
w_done:
    mov     x0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, tids
    add     x19, x19, :lo12:tids

    mov     x20, #0
create_loop:
    add     x0, x19, x20, lsl #3
    mov     x1, #0
    adr     x2, worker
    mov     x3, x20                 // arg = (void *)t
    bl      pthread_create
    add     x20, x20, #1
    cmp     x20, #NTHREADS
    b.lo    create_loop

    mov     x20, #0
join_loop:
    ldr     x0, [x19, x20, lsl #3]
    mov     x1, #0
    bl      pthread_join
    add     x20, x20, #1
    cmp     x20, #NTHREADS
    b.lo    join_loop

    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    adrp    x1, best
    ldr     x1, [x1, :lo12:best]
    bl      printf

    mov     w0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section .rodata
fmt:    .asciz "max = %ld\n"

    .bss
    .p2align 3
tids:   .space NTHREADS * 8
best:   .space 8                    // long best = 0;
