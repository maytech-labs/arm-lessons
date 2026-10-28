// msgpass.s - passing a message between threads with release/acquire.
// The producer thread writes data = 42 with a plain store, then sets flag = 1
// with stlr (store-release). The main thread spins with ldar (load-acquire)
// until it sees flag == 1, then reads data with a plain load.
// Release/acquire guarantees that once main sees the flag, it also sees 42.
//
// Build: make msgpass        (the Makefile links with -pthread)
// Run:   ./msgpass
// Expected output, every time:
//     flag is set, data = 42

    .text
    .global main

// void *producer(void *arg)
producer:
    adrp    x1, data
    add     x1, x1, :lo12:data
    mov     x2, #42
    str     x2, [x1]                // data = 42            (plain store)
    adrp    x1, flag
    add     x1, x1, :lo12:flag
    mov     w2, #1
    stlr    w2, [x1]                // flag = 1, release: data is visible first
    mov     x0, #0
    ret

main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]

    adrp    x0, tid
    add     x0, x0, :lo12:tid
    mov     x1, #0
    adr     x2, producer
    mov     x3, #0
    bl      pthread_create

    adrp    x19, flag
    add     x19, x19, :lo12:flag
wait:
    ldar    w1, [x19]               // read flag, acquire: later loads stay later
    cbz     w1, wait                // while (flag == 0) ;

    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    adrp    x1, data
    ldr     x1, [x1, :lo12:data]    // plain load: guaranteed to see 42
    bl      printf

    adrp    x0, tid
    ldr     x0, [x0, :lo12:tid]
    mov     x1, #0
    bl      pthread_join

    mov     w0, #0
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section .rodata
fmt:    .asciz "flag is set, data = %ld\n"

    .bss
    .p2align 3
tid:    .space 8
data:   .space 8
flag:   .space 4
