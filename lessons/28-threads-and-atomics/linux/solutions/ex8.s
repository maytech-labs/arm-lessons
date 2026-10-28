// ex8.s - Exercise 28.8: a ticket lock. Like a bakery queue: each thread
// takes a ticket (an atomic fetch-and-add on next_ticket) and waits until
// now_serving equals its ticket. Unlock just moves now_serving on by one.
// Unlike a spinlock, threads get the lock in the order they asked for it.
//
//     struct ticket_lock { unsigned next_ticket; unsigned now_serving; };
//
// Four threads each do counter++ 200000 times under the lock.
//
// Build: make ex8
// Run:   ./ex8               (run it several times)
// Expected output, every time:
//     counter = 800000

    .arch armv8.1-a

    .equ NTHREADS, 4
    .equ ITERS, 200000
    .equ T_NEXT, 0
    .equ T_SERVING, 4

    .text
    .global main

// void ticket_lock(struct ticket_lock *t)
// While it is not our turn we call sched_yield() to give our core away. If
// there are more busy threads than cores, the thread whose turn it is may not
// even be running; without the yield, everyone behind it would spin for a
// whole scheduler time slice at every hand-over, and the program would crawl.
ticket_lock:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     w1, #1
    ldadd   w1, w19, [x0]           // my = t->next_ticket++   (atomic)
    add     x20, x0, #T_SERVING     // ldar takes no offset: compute the address
tl_wait:
    ldar    w4, [x20]               // acquire: the previous holder's writes are visible
    cmp     w4, w19
    b.eq    tl_mine
    bl      sched_yield             // not my turn yet: let another thread run
    b       tl_wait
tl_mine:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// void ticket_unlock(struct ticket_lock *t)
// Only the lock holder writes now_serving, so a plain load is fine here.
ticket_unlock:
    ldr     w1, [x0, #T_SERVING]
    add     w1, w1, #1
    add     x2, x0, #T_SERVING
    stlr    w1, [x2]                // release: our writes go out before the next turn
    ret

worker:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, tlock
    add     x19, x19, :lo12:tlock
    movz    x20, #0x0d40            // 200000 = 0x30d40
    movk    x20, #0x3, lsl #16
w_loop:
    mov     x0, x19
    bl      ticket_lock
    adrp    x1, counter
    add     x1, x1, :lo12:counter
    ldr     x2, [x1]
    add     x2, x2, #1
    str     x2, [x1]
    mov     x0, x19
    bl      ticket_unlock
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
tids:    .space NTHREADS * 8
counter: .space 8
tlock:   .space 8                   // both fields start at 0
