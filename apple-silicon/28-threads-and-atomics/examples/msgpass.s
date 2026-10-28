// msgpass.s - passing a message between threads with release/acquire.
// The producer thread writes data = 42 with a plain store, then sets flag = 1
// with stlr (store-release). The main thread spins with ldar (load-acquire)
// until it sees flag == 1, then reads data with a plain load.
// Release/acquire guarantees that once main sees the flag, it also sees 42.
//
// Build: make msgpass        (no -pthread needed on macOS)
// Run:   ./msgpass
// Expected output, every time:
//     flag is set, data = 42

    .text
    .global _main

// void *producer(void *arg)
producer:
    adrp    x1, data@PAGE
    add     x1, x1, data@PAGEOFF
    mov     x2, #42
    str     x2, [x1]                // data = 42            (plain store)
    adrp    x1, flag@PAGE
    add     x1, x1, flag@PAGEOFF
    mov     w2, #1
    stlr    w2, [x1]                // flag = 1, release: data is visible first
    mov     x0, #0
    ret

_main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]

    adrp    x0, tid@PAGE
    add     x0, x0, tid@PAGEOFF
    mov     x1, #0
    adr     x2, producer
    mov     x3, #0
    bl      _pthread_create

    adrp    x19, flag@PAGE
    add     x19, x19, flag@PAGEOFF
wait:
    ldar    w1, [x19]               // read flag, acquire: later loads stay later
    cbz     w1, wait                // while (flag == 0) ;

    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    adrp    x1, data@PAGE
    ldr     x1, [x1, data@PAGEOFF]    // plain load: guaranteed to see 42
    sub     sp, sp, #16             // variadic arguments go on the stack
    str     x1, [sp]
    bl      _printf
    add     sp, sp, #16

    adrp    x0, tid@PAGE
    ldr     x0, [x0, tid@PAGEOFF]
    mov     x1, #0
    bl      _pthread_join

    mov     w0, #0
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt:    .asciz "flag is set, data = %ld\n"

    .bss
    .p2align 3
tid:    .space 8
data:   .space 8
flag:   .space 4
