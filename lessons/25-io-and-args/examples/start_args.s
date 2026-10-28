// start_args.s - read argc and argv straight off the stack at _start (lesson 25)
//
// A freestanding program (no C library). The kernel leaves this on the stack:
//   [sp]       argc
//   [sp, #8]   argv[0]
//   [sp, #16]  argv[1] ...
//              NULL            (argv[argc])
//              envp[0] ... NULL
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
    .global _start
    .p2align 2
_start:
    ldr x19, [sp]               // x19 = argc
    add x20, sp, #8             // x20 = argv = address of argv[0]
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
    mov x0, #1                  // write(1, argv[i], len)
    mov x1, x22
    mov x8, #64
    svc #0

    mov x0, #1                  // write(1, "\n", 1)
    adrp x1, newline
    add x1, x1, :lo12:newline
    mov x2, #1
    mov x8, #64
    svc #0

    add x21, x21, #1
    b start_loop

start_done:
    mov x0, x19                 // exit(argc)
    mov x8, #93
    svc #0

    .section .rodata
newline: .ascii "\n"
