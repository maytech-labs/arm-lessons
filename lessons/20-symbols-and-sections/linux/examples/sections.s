// sections.s - one symbol in each section; see where the linker put them.
//
// C:      const char greeting[] = "hi";     // .rodata
//         long counter = 5;                 // .data
//         long buffer[100];                 // .bss
//         int main(void) { ... }            // .text
//
// Build:  make
// Run:    ./sections
// Look:   nm sections | grep -E ' (greeting|counter|buffer|main)$'
//         objdump -h sections
// Expected output:
//   code < constants: yes
//   constants < data: yes
//   data < bss: yes
//   bss < stack: yes
//   counter = 5, buffer[0] = 0

    .global main

    .section .rodata
greeting:
    .asciz "hi"
fmt_cmp:
    .asciz "%s < %s: %s\n"
fmt_end:
    .asciz "counter = %ld, buffer[0] = %ld\n"
s_code:  .asciz "code"
s_const: .asciz "constants"
s_data:  .asciz "data"
s_bss:   .asciz "bss"
s_stack: .asciz "stack"
s_yes:   .asciz "yes"
s_no:    .asciz "no"

    .data
    .p2align 3
counter:
    .quad 5                     // has a starting value: stored in the file

    .bss
    .p2align 3
buffer:
    .space 800                  // zero-filled at load time: no bytes in the file

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    adrp x19, main
    add x19, x19, :lo12:main
    adrp x20, greeting
    add x20, x20, :lo12:greeting
    adrp x21, counter
    add x21, x21, :lo12:counter
    adrp x22, buffer
    add x22, x22, :lo12:buffer

    mov x0, x19
    mov x1, x20
    adrp x2, s_code
    add x2, x2, :lo12:s_code
    adrp x3, s_const
    add x3, x3, :lo12:s_const
    bl compare
    mov x0, x20
    mov x1, x21
    adrp x2, s_const
    add x2, x2, :lo12:s_const
    adrp x3, s_data
    add x3, x3, :lo12:s_data
    bl compare
    mov x0, x21
    mov x1, x22
    adrp x2, s_data
    add x2, x2, :lo12:s_data
    adrp x3, s_bss
    add x3, x3, :lo12:s_bss
    bl compare
    mov x0, x22
    mov x1, sp
    adrp x2, s_bss
    add x2, x2, :lo12:s_bss
    adrp x3, s_stack
    add x3, x3, :lo12:s_stack
    bl compare

    ldr x1, [x21]
    ldr x2, [x22]
    adrp x0, fmt_end
    add x0, x0, :lo12:fmt_end
    bl printf

    mov w0, #0
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// void compare(void *a, void *b, const char *name_a, const char *name_b)
//   prints "name_a < name_b: yes/no"
compare:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    cmp x0, x1                  // addresses: unsigned compare
    mov x1, x2
    mov x2, x3
    adrp x3, s_yes
    add x3, x3, :lo12:s_yes
    adrp x9, s_no
    add x9, x9, :lo12:s_no
    csel x3, x3, x9, lo
    adrp x0, fmt_cmp
    add x0, x0, :lo12:fmt_cmp
    bl printf
    ldp x29, x30, [sp], #16
    ret
