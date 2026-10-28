// start_args.s - argc and argv as main receives them, no stdio (lesson 25, macOS)
//
// On Linux this example is a freestanding _start program that reads argc and
// argv off the stack. macOS programs always start in _main (dyld and libSystem
// run first), so here argc and argv simply arrive in x0 and x1. The loop is the
// same: strlen by hand, then write each argument.
//
// Build: make start_args
// Run:   ./start_args red green; echo $?
// Expected output:
//   ./start_args
//   red
//   green
//   3
// (the last line is the exit status, which is argc)

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov w19, w0                 // x19 = argc
    mov x20, x1                 // x20 = argv
    mov x21, #0                 // i = 0

start_loop:
    cmp x21, x19
    b.ge start_done
    ldr x22, [x20, x21, lsl #3] // x22 = argv[i]

    mov x2, #0                  // strlen by hand: x2 = length
start_strlen:
    ldrb w3, [x22, x2]
    cbz w3, start_strlen_done
    add x2, x2, #1
    b start_strlen
start_strlen_done:
    mov w0, #1                  // write(1, argv[i], len)
    mov x1, x22
    bl _write

    mov w0, #1                  // write(1, "\n", 1)
    adrp x1, newline@PAGE
    add x1, x1, newline@PAGEOFF
    mov x2, #1
    bl _write

    add x21, x21, #1
    b start_loop

start_done:
    mov w0, w19                 // return argc: it becomes the exit status
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
newline: .asciz "\n"             // __cstring holds only NUL-terminated strings
