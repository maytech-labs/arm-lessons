// race.s - a data race. Four threads each add 1 to a shared counter one
// million times, using a plain load, add, store. Increments get lost.
//
// Build: make race           (the Makefile links with -pthread)
// Run:   ./race              (run it several times)
// Expected output: the second number changes from run to run and is almost
// always well below 4000000, for example
//     expected 4000000, got 1462318

    .equ NTHREADS, 4

    .text
    .global main

// void *worker(void *arg): counter = counter + 1, one million times.
// This is exactly what `counter++` compiles to: nothing stops two threads
// from both loading the same old value.
worker:
    adrp    x1, counter
    add     x1, x1, :lo12:counter
    movz    x2, #0x4240             // x2 = 1000000 = 0xf4240
    movk    x2, #0xf, lsl #16
worker_loop:
    ldr     x3, [x1]                // read counter
    add     x3, x3, #1              // add one
    str     x3, [x1]                // write it back
    subs    x2, x2, #1
    b.ne    worker_loop
    mov     x0, #0                  // return NULL
    ret

main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, tids
    add     x19, x19, :lo12:tids

    mov     x20, #0
create_loop:
    add     x0, x19, x20, lsl #3    // &tids[i]
    mov     x1, #0                  // default attributes
    adr     x2, worker
    mov     x3, #0                  // arg: unused
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
    movz    x1, #0x0900             // x1 = 4000000 = 0x3d0900
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
