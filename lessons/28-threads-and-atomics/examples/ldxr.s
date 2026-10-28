// ldxr.s - the race fixed without a lock: each increment is an atomic
// read-modify-write built from an exclusive load (ldxr) and an exclusive
// store (stxr), retried until the store succeeds.
//
// Build: make ldxr           (the Makefile links with -pthread)
// Run:   ./ldxr              (run it several times)
// Expected output, every time:
//     expected 4000000, got 4000000

    .equ NTHREADS, 4

    .text
    .global main

// void *worker(void *arg): atomically add 1 to counter, one million times.
worker:
    adrp    x1, counter
    add     x1, x1, :lo12:counter
    movz    x2, #0x4240             // 1000000
    movk    x2, #0xf, lsl #16
worker_loop:
retry:
    ldxr    x3, [x1]                // load counter AND start watching its address
    add     x3, x3, #1
    stxr    w4, x3, [x1]            // store only if nobody wrote it since the ldxr;
                                    // w4 = 0 on success, 1 on failure
    cbnz    w4, retry               // failed: someone got in first, start over
    subs    x2, x2, #1
    b.ne    worker_loop
    mov     x0, #0
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
