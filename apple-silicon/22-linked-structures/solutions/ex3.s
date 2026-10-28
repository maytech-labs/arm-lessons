// ex3.s - sum and maximum of a linked list (lesson 22, exercise 22.3, macOS)
//
// Build: make ex3
// Run:   ./ex3
// Expected output:
//   list: 4 -2 9 7
//   sum: 18
//   max: 9

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

    .text
    .global _main
    .p2align 2

// long list_sum(struct node *p)
list_sum:
    mov x1, #0                  // sum = 0
list_sum_loop:
    cbz x0, list_sum_done
    ldr x9, [x0, #NODE_VALUE]
    add x1, x1, x9              // sum += p->value
    ldr x0, [x0, #NODE_NEXT]
    b list_sum_loop
list_sum_done:
    mov x0, x1
    ret

// long list_max(struct node *p)        (p must not be NULL)
list_max:
    ldr x1, [x0, #NODE_VALUE]   // best = first value
    ldr x0, [x0, #NODE_NEXT]
list_max_loop:
    cbz x0, list_max_done
    ldr x9, [x0, #NODE_VALUE]
    cmp x9, x1
    csel x1, x9, x1, gt         // signed: -2 must lose to 4
    ldr x0, [x0, #NODE_NEXT]
    b list_max_loop
list_max_done:
    mov x0, x1
    ret

// struct node *push_front(struct node *head, long value)
push_front:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
    mov x0, #NODE_SIZE
    bl _malloc
    cbz x0, out_of_memory
    str x20, [x0, #NODE_VALUE]
    str x19, [x0, #NODE_NEXT]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// void print_list(const char *label, struct node *head)
print_list:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x1
    bl _printf                  // printf(label)
print_list_loop:
    cbz x19, print_list_done
    adrp x0, fmt_item@PAGE
    add x0, x0, fmt_item@PAGEOFF
    sub sp, sp, #16
    ldr x9, [x19, #NODE_VALUE]
    str x9, [sp]                // variadic argument goes on the stack
    bl _printf
    add sp, sp, #16
    ldr x19, [x19, #NODE_NEXT]
    b print_list_loop
print_list_done:
    mov w0, #10
    bl _putchar
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// void free_list(struct node *head)
free_list:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
free_list_loop:
    cbz x19, free_list_done
    ldr x20, [x19, #NODE_NEXT]
    mov x0, x19
    bl _free
    mov x19, x20
    b free_list_loop
free_list_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

out_of_memory:
    adrp x0, msg_oom@PAGE
    add x0, x0, msg_oom@PAGEOFF
    bl _puts
    mov w0, #1
    bl _exit

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, #0
    mov x0, x19
    mov x1, #7
    bl push_front
    mov x1, #9
    bl push_front
    mov x1, #-2
    bl push_front
    mov x1, #4
    bl push_front               // push_front returns the head in x0: chain them
    mov x19, x0                 // list: 4 -2 9 7

    adrp x0, lbl_list@PAGE
    add x0, x0, lbl_list@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    bl list_sum
    sub sp, sp, #16
    str x0, [sp]                // variadic argument goes on the stack
    adrp x0, fmt_sum@PAGE
    add x0, x0, fmt_sum@PAGEOFF
    bl _printf
    add sp, sp, #16

    mov x0, x19
    bl list_max
    sub sp, sp, #16
    str x0, [sp]                // variadic argument goes on the stack
    adrp x0, fmt_max@PAGE
    add x0, x0, fmt_max@PAGEOFF
    bl _printf
    add sp, sp, #16

    mov x0, x19
    bl free_list
    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt_item: .asciz " %ld"
lbl_list: .asciz "list:"
fmt_sum:  .asciz "sum: %ld\n"
fmt_max:  .asciz "max: %ld\n"
msg_oom:  .asciz "out of memory"
