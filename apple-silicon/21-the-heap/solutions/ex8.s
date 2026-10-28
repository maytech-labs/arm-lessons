// ex8.s - a bump allocator on top of one mmap'd page (lesson 21, macOS, exercise 21.8)
//
// Build: make ex8
// Run:   ./ex8
// Expected output:
//   alloc 10 -> offset 0
//   alloc 20 -> offset 16
//   alloc 5 -> offset 48
//   alloc 5000 -> NULL
//   used 64 of 4096

    .equ ARENA_SIZE, 4096
    .equ PROT_RW,    3              // PROT_READ | PROT_WRITE
    .equ MAP_PRIV_ANON, 0x1002      // MAP_PRIVATE | MAP_ANON  (macOS values)

    .bss
    .p2align 3
arena:
    .space 8                        // char *arena;  start of the page
arena_used:
    .space 8                        // long arena_used;  bytes handed out so far

    .section __TEXT,__const
    .p2align 3
sizes:
    .quad 10, 20, 5, 5000
    .equ NSIZES, 4

    .section __TEXT,__cstring
fmt_ok:
    .asciz "alloc %ld -> offset %ld\n"
fmt_null:
    .asciz "alloc %ld -> NULL\n"
fmt_used:
    .asciz "used %ld of %ld\n"

    .text
    .p2align 2

// int arena_init(void): map one page; 0 on success, -1 on failure
arena_init:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    mov  x0, #0                     // mmap(NULL, 4096, PROT_RW, MAP_PRIVATE|MAP_ANON, -1, 0)
    mov  x1, #ARENA_SIZE
    mov  x2, #PROT_RW
    mov  x3, #MAP_PRIV_ANON
    mov  w4, #-1
    mov  x5, #0
    bl   _mmap
    cmn  x0, #1                     // MAP_FAILED is (void *)-1
    b.eq arena_init_fail
    adrp x1, arena@PAGE
    str  x0, [x1, arena@PAGEOFF]
    adrp x1, arena_used@PAGE
    str  xzr, [x1, arena_used@PAGEOFF]
    mov  w0, #0
arena_init_done:
    ldp  x29, x30, [sp], #16
    ret
arena_init_fail:
    mov  w0, #-1
    b    arena_init_done

// void *bump_alloc(long n): n rounded up to 16 so every block stays 16-aligned.
// Returns NULL when the page is full. There is no free for single blocks.
bump_alloc:
    add  x0, x0, #15                // n = (n + 15) & ~15;
    and  x0, x0, #~15
    adrp x1, arena_used@PAGE
    ldr  x2, [x1, arena_used@PAGEOFF]
    add  x3, x2, x0                 // new_used = used + n
    cmp  x3, #ARENA_SIZE
    b.hi bump_alloc_full
    str  x3, [x1, arena_used@PAGEOFF]
    adrp x1, arena@PAGE
    ldr  x1, [x1, arena@PAGEOFF]
    add  x0, x1, x2                 // return arena + old used;
    ret
bump_alloc_full:
    mov  x0, #0
    ret

// void arena_release(void): give the whole page back at once
arena_release:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, arena@PAGE             // munmap(arena, 4096);
    ldr  x0, [x0, arena@PAGEOFF]
    mov  x1, #ARENA_SIZE
    bl   _munmap
    ldp  x29, x30, [sp], #16
    ret

    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = i, x20 = sizes[i]

    bl   arena_init
    cbnz w0, main_fail

    mov  x19, #0
main_loop:
    cmp  x19, #NSIZES
    b.ge main_loop_done
    adrp x0, sizes@PAGE
    add  x0, x0, sizes@PAGEOFF
    ldr  x20, [x0, x19, lsl #3]
    mov  x0, x20
    bl   bump_alloc
    cbz  x0, main_null
    adrp x1, arena@PAGE             // offset = p - arena
    ldr  x1, [x1, arena@PAGEOFF]
    sub  x2, x0, x1
    adrp x0, fmt_ok@PAGE
    add  x0, x0, fmt_ok@PAGEOFF
    mov  x1, x20
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    bl   _printf
    add  sp, sp, #16
    b    main_next
main_null:
    adrp x0, fmt_null@PAGE
    add  x0, x0, fmt_null@PAGEOFF
    mov  x1, x20
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16
main_next:
    add  x19, x19, #1
    b    main_loop
main_loop_done:

    adrp x0, fmt_used@PAGE
    add  x0, x0, fmt_used@PAGEOFF
    adrp x1, arena_used@PAGE
    ldr  x1, [x1, arena_used@PAGEOFF]
    mov  x2, #ARENA_SIZE
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    bl   _printf
    add  sp, sp, #16

    bl   arena_release
    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
