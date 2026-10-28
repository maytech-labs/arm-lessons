// mmap_page.s - ask the kernel for a page of memory directly, like malloc does (lesson 21)
//
// Uses the raw mmap and munmap system calls (lesson 05 style svc), then
// prints a message that was built inside the new page.
//
// Build: make mmap_page
// Run:   ./mmap_page
// Expected output:
//   got 4096 bytes from mmap
//   hello from a fresh page
//   page returned with munmap

    .equ SYS_MUNMAP, 215
    .equ SYS_MMAP,   222
    .equ PAGE_SIZE,  4096
    .equ PROT_READ,  1
    .equ PROT_WRITE, 2
    .equ MAP_PRIVATE,   0x02
    .equ MAP_ANONYMOUS, 0x20        // not backed by a file: just zeroed memory

    .section .rodata
msg_got:
    .asciz "got 4096 bytes from mmap"
text:
    .asciz "hello from a fresh page"
msg_back:
    .asciz "page returned with munmap"

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]              // x19 = page

    // page = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    mov  x0, #0                     // addr: let the kernel choose
    mov  x1, #PAGE_SIZE             // length
    mov  x2, #(PROT_READ | PROT_WRITE)
    mov  x3, #(MAP_PRIVATE | MAP_ANONYMOUS)
    mov  x4, #-1                    // fd: none
    mov  x5, #0                     // offset
    mov  x8, #SYS_MMAP
    svc  #0
    tbnz x0, #63, main_fail         // negative result = -errno
    mov  x19, x0

    adrp x0, msg_got
    add  x0, x0, :lo12:msg_got
    bl   puts

    // copy text into the page, byte by byte, including the '\0'
    adrp x1, text
    add  x1, x1, :lo12:text
    mov  x2, x19
main_copy:
    ldrb w3, [x1], #1
    strb w3, [x2], #1
    cbnz w3, main_copy

    mov  x0, x19                    // puts(page);
    bl   puts

    mov  x0, x19                    // munmap(page, 4096);
    mov  x1, #PAGE_SIZE
    mov  x8, #SYS_MUNMAP
    svc  #0
    cbnz x0, main_fail              // 0 means success

    adrp x0, msg_back
    add  x0, x0, :lo12:msg_back
    bl   puts

    mov  w0, #0
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
