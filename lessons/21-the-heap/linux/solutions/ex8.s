// ex8.s - a bump allocator on top of one mmap'd page (lesson 21, exercise 21.8)
//
// Build: make ex8
// Run:   ./ex8
// Expected output:
//   alloc 10 -> offset 0
//   alloc 20 -> offset 16
//   alloc 5 -> offset 48
//   alloc 5000 -> NULL
//   used 64 of 4096

    .equ SYS_MUNMAP, 215
    .equ SYS_MMAP,   222
    .equ ARENA_SIZE, 4096
    .equ PROT_RW,    3              // PROT_READ | PROT_WRITE
    .equ MAP_PRIV_ANON, 0x22        // MAP_PRIVATE | MAP_ANONYMOUS

    .bss
    .p2align 3
arena:
    .space 8                        // char *arena;  start of the page
arena_used:
    .space 8                        // long arena_used;  bytes handed out so far

    .section .rodata
sizes:
    .quad 10, 20, 5, 5000
    .equ NSIZES, 4
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
    mov  x0, #0
    mov  x1, #ARENA_SIZE
    mov  x2, #PROT_RW
    mov  x3, #MAP_PRIV_ANON
    mov  x4, #-1
    mov  x5, #0
    mov  x8, #SYS_MMAP
    svc  #0
    tbnz x0, #63, arena_init_fail
    adrp x1, arena
    str  x0, [x1, :lo12:arena]
    adrp x1, arena_used
    str  xzr, [x1, :lo12:arena_used]
    mov  w0, #0
    ret
arena_init_fail:
    mov  w0, #-1
    ret

// void *bump_alloc(long n): n rounded up to 16 so every block stays 16-aligned.
// Returns NULL when the page is full. There is no free for single blocks.
bump_alloc:
    add  x0, x0, #15                // n = (n + 15) & ~15;
    and  x0, x0, #~15
    adrp x1, arena_used
    ldr  x2, [x1, :lo12:arena_used]
    add  x3, x2, x0                 // new_used = used + n
    cmp  x3, #ARENA_SIZE
    b.hi bump_alloc_full
    str  x3, [x1, :lo12:arena_used]
    adrp x1, arena
    ldr  x1, [x1, :lo12:arena]
    add  x0, x1, x2                 // return arena + old used;
    ret
bump_alloc_full:
    mov  x0, #0
    ret

// void arena_release(void): give the whole page back at once
arena_release:
    adrp x0, arena
    ldr  x0, [x0, :lo12:arena]
    mov  x1, #ARENA_SIZE
    mov  x8, #SYS_MUNMAP
    svc  #0
    ret

    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = i, x20 = sizes[i]

    bl   arena_init
    cbnz w0, main_fail

    mov  x19, #0
main_loop:
    cmp  x19, #NSIZES
    b.ge main_loop_done
    adrp x0, sizes
    add  x0, x0, :lo12:sizes
    ldr  x20, [x0, x19, lsl #3]
    mov  x0, x20
    bl   bump_alloc
    cbz  x0, main_null
    adrp x1, arena                  // offset = p - arena
    ldr  x1, [x1, :lo12:arena]
    sub  x2, x0, x1
    adrp x0, fmt_ok
    add  x0, x0, :lo12:fmt_ok
    mov  x1, x20
    bl   printf
    b    main_next
main_null:
    adrp x0, fmt_null
    add  x0, x0, :lo12:fmt_null
    mov  x1, x20
    bl   printf
main_next:
    add  x19, x19, #1
    b    main_loop
main_loop_done:

    adrp x0, fmt_used
    add  x0, x0, :lo12:fmt_used
    adrp x1, arena_used
    ldr  x1, [x1, :lo12:arena_used]
    mov  x2, #ARENA_SIZE
    bl   printf

    bl   arena_release
    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
