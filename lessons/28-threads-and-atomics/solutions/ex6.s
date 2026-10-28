// ex6.s - Exercise 28.6: a spinlock built from swpa (atomic swap with
// acquire) and stlr (store-release). Four threads protect a plain
// counter++ with it, one million times each.
//
// Build: make ex6
// Run:   ./ex6               (run it several times)
// Expected output, every time:
//     counter = 4000000

    .arch armv8.1-a

    .equ NTHREADS, 4

    .text
    .global main

// void lock(int *l): swap in 1; if the old value was 0, the lock is ours.
lock:
    mov     w1, #1
lock_retry:
    swpa    w1, w2, [x0]            // atomically: w2 = *l; *l = 1   (acquire)
    cbnz    w2, lock_retry          // it was already 1: someone else holds it
    ret

// void unlock(int *l)
unlock:
    stlr    wzr, [x0]               // *l = 0, release
    ret

worker:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, the_lock
    add     x19, x19, :lo12:the_lock
    movz    x20, #0x4240            // 1000000
    movk    x20, #0xf, lsl #16
w_loop:
    mov     x0, x19
    bl      lock
    adrp    x1, counter
    add     x1, x1, :lo12:counter
    ldr     x2, [x1]
    add     x2, x2, #1
    str     x2, [x1]
    mov     x0, x19
    bl      unlock
    subs    x20, x20, #1
    b.ne    w_loop
    mov     x0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
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
    mov     x3, #0
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
    adrp    x1, counter
    ldr     x1, [x1, :lo12:counter]
    bl      printf

    mov     w0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section .rodata
fmt:    .asciz "counter = %ld\n"

    .bss
    .p2align 3
tids:     .space NTHREADS * 8
counter:  .space 8
the_lock: .space 4
