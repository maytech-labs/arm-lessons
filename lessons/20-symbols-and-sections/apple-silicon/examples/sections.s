// sections.s - one symbol in each section; see where the linker put them (macOS).
//
// C:      const char greeting[] = "hi";     // .rodata
//         long counter = 5;                 // .data
//         long buffer[100];                 // .bss
//         int main(void) { ... }            // .text
//
// Build:  make
// Run:    ./sections
// Look:   nm sections | grep -E " (greeting|counter|buffer|_main)$"
//         objdump -h sections
// Expected output:
//   code < constants: yes
//   constants < data: yes
//   data < bss: yes
//   bss < stack: yes
//   counter = 5, buffer[0] = 0

    .global _main

    .section __TEXT,__const
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
_main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    adrp x19, _main@PAGE
    add x19, x19, _main@PAGEOFF
    adrp x20, greeting@PAGE
    add x20, x20, greeting@PAGEOFF
    adrp x21, counter@PAGE
    add x21, x21, counter@PAGEOFF
    adrp x22, buffer@PAGE
    add x22, x22, buffer@PAGEOFF

    mov x0, x19
    mov x1, x20
    adrp x2, s_code@PAGE
    add x2, x2, s_code@PAGEOFF
    adrp x3, s_const@PAGE
    add x3, x3, s_const@PAGEOFF
    bl compare
    mov x0, x20
    mov x1, x21
    adrp x2, s_const@PAGE
    add x2, x2, s_const@PAGEOFF
    adrp x3, s_data@PAGE
    add x3, x3, s_data@PAGEOFF
    bl compare
    mov x0, x21
    mov x1, x22
    adrp x2, s_data@PAGE
    add x2, x2, s_data@PAGEOFF
    adrp x3, s_bss@PAGE
    add x3, x3, s_bss@PAGEOFF
    bl compare
    mov x0, x22
    mov x1, sp
    adrp x2, s_bss@PAGE
    add x2, x2, s_bss@PAGEOFF
    adrp x3, s_stack@PAGE
    add x3, x3, s_stack@PAGEOFF
    bl compare

    ldr x1, [x21]
    ldr x2, [x22]
    adrp x0, fmt_end@PAGE
    add x0, x0, fmt_end@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    bl _printf
    add sp, sp, #16

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
    adrp x3, s_yes@PAGE
    add x3, x3, s_yes@PAGEOFF
    adrp x9, s_no@PAGE
    add x9, x9, s_no@PAGEOFF
    csel x3, x3, x9, lo
    adrp x0, fmt_cmp@PAGE
    add x0, x0, fmt_cmp@PAGEOFF
    sub sp, sp, #32             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    str x2, [sp, #8]
    str x3, [sp, #16]
    bl _printf
    add sp, sp, #32
    ldp x29, x30, [sp], #16
    ret
