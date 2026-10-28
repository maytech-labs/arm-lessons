// mutex.s - the race from race.s, fixed with a pthread mutex. Each thread
// locks the mutex, does counter++, and unlocks it, one million times.
//
// Build: make mutex          (the Makefile links with -pthread)
// Run:   ./mutex             (run it several times)
// Expected output, every time:
//     expected 4000000, got 4000000

    .equ NTHREADS, 4

    .text
    .global main

// void *worker(void *arg)
// It calls functions, so it needs a frame, and callee-saved registers for
// the values it keeps across those calls.
worker:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, lock
    add     x19, x19, :lo12:lock    // x19 = &lock     (survives the calls)
    movz    x20, #0x4240            // x20 = 1000000   (survives the calls)
    movk    x20, #0xf, lsl #16
worker_loop:
    mov     x0, x19
    bl      pthread_mutex_lock      // pthread_mutex_lock(&lock);
    adrp    x1, counter             //   only one thread at a time runs
    add     x1, x1, :lo12:counter   //   these four instructions
    ldr     x2, [x1]
    add     x2, x2, #1
    str     x2, [x1]                //   counter++;
    mov     x0, x19
    bl      pthread_mutex_unlock    // pthread_mutex_unlock(&lock);
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

    adrp    x0, lock
    add     x0, x0, :lo12:lock
    mov     x1, #0                  // default mutex attributes
    bl      pthread_mutex_init      // pthread_mutex_init(&lock, NULL);

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

    adrp    x0, lock
    add     x0, x0, :lo12:lock
    bl      pthread_mutex_destroy

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
lock:    .space 64          // pthread_mutex_t: 48 bytes on Linux, 64 on macOS
