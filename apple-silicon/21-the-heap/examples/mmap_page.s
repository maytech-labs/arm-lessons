// mmap_page.s - ask the kernel for a page of memory directly, like malloc does (lesson 21, macOS)
//
// Calls libSystem's mmap and munmap (thin wrappers around the system calls),
// then prints a message that was built inside the new page.
//
// Build: make mmap_page
// Run:   ./mmap_page
// Expected output:
//   got 4096 bytes from mmap
//   hello from a fresh page
//   page returned with munmap

    .equ PAGE_SIZE,  4096
    .equ PROT_READ,  1
    .equ PROT_WRITE, 2
    .equ MAP_PRIVATE,   0x0002
    .equ MAP_ANON,      0x1000      // not backed by a file: just zeroed memory (macOS value)

    .section __TEXT,__cstring
msg_got:
    .asciz "got 4096 bytes from mmap"
text:
    .asciz "hello from a fresh page"
msg_back:
    .asciz "page returned with munmap"

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]              // x19 = page

    // page = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0);
    mov  x0, #0                     // addr: let the kernel choose
    mov  x1, #PAGE_SIZE             // length
    mov  w2, #(PROT_READ | PROT_WRITE)
    mov  w3, #(MAP_PRIVATE | MAP_ANON)
    mov  w4, #-1                    // fd: none
    mov  x5, #0                     // offset
    bl   _mmap
    cmn  x0, #1                     // failure returns MAP_FAILED, which is (void *)-1
    b.eq main_fail
    mov  x19, x0

    adrp x0, msg_got@PAGE
    add  x0, x0, msg_got@PAGEOFF
    bl   _puts

    // copy text into the page, byte by byte, including the '\0'
    adrp x1, text@PAGE
    add  x1, x1, text@PAGEOFF
    mov  x2, x19
main_copy:
    ldrb w3, [x1], #1
    strb w3, [x2], #1
    cbnz w3, main_copy

    mov  x0, x19                    // puts(page);
    bl   _puts

    mov  x0, x19                    // munmap(page, 4096);
    mov  x1, #PAGE_SIZE
    bl   _munmap
    cbnz w0, main_fail              // 0 means success

    adrp x0, msg_back@PAGE
    add  x0, x0, msg_back@PAGEOFF
    bl   _puts

    mov  w0, #0
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
