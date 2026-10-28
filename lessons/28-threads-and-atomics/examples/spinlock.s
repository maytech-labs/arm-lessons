// spinlock.s - a lock you build yourself. spin_lock uses ldaxr/stxr
// (load-acquire exclusive) to change the lock word from 0 to 1; spin_unlock
// uses stlr (store-release) to put 0 back. Four threads protect a plain
// counter++ with it.
//
// Build: make spinlock       (the Makefile links with -pthread)
// Run:   ./spinlock          (run it several times)
// Expected output, every time:
//     expected 4000000, got 4000000

    .equ NTHREADS, 4

    .text
    .global main

// void spin_lock(int *lock): wait until *lock is 0, then set it to 1.
spin_lock:
    mov     w2, #1
spin_retry:
    ldaxr   w1, [x0]                // read the lock word (acquire), start watching
    cbnz    w1, spin_retry          // 1 = someone holds it: keep trying
    stxr    w3, w2, [x0]            // try to write 1
    cbnz    w3, spin_retry          // someone else wrote first: try again
    ret                             // we own the lock

// void spin_unlock(int *lock): *lock = 0, with release ordering, so every
// write we made inside the lock is visible before the lock looks free.
spin_unlock:
    stlr    wzr, [x0]
    ret

// void *worker(void *arg)
worker:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, lock
    add     x19, x19, :lo12:lock
    movz    x20, #0x4240            // 1000000
    movk    x20, #0xf, lsl #16
worker_loop:
    mov     x0, x19
    bl      spin_lock
    adrp    x1, counter
    add     x1, x1, :lo12:counter
    ldr     x2, [x1]                // plain counter++, safe inside the lock
    add     x2, x2, #1
    str     x2, [x1]
    mov     x0, x19
    bl      spin_unlock
    subs    x20, x20, #1
    b.ne    worker_loop
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
    movz    x1, #0x0900             // 4000000
    movk    x1, #0x3d, lsl #16
    adrp    x2, counter
    ldr     x2, [x2, :lo12:counter]
    bl      printf

    mov     w0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section .rodata
fmt:    .asciz "expected %ld, got %ld\n"

    .bss
    .p2align 3
tids:    .space NTHREADS * 8
counter: .space 8
lock:    .space 4                   // int lock = 0;  (0 = free, 1 = held)
