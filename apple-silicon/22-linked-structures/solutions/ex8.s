// ex8.s - reverse a linked list with recursion instead of a loop (lesson 22, exercise 22.8, macOS)
//
// Build: make ex8
// Run:   ./ex8
// Expected output:
//   before: 1 2 3 4 5
//   reversed: 5 4 3 2 1

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

    .text
    .global _main
    .p2align 2

// struct node *reverse_rec(struct node *head)
//     if (head == NULL || head->next == NULL) return head;
//     struct node *rest = reverse_rec(head->next);
//     head->next->next = head;    // the old second node now points back
//     head->next = NULL;
//     return rest;
reverse_rec:
    cbz x0, reverse_rec_base
    ldr x9, [x0, #NODE_NEXT]
    cbz x9, reverse_rec_base
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                 // head
    mov x0, x9
    bl reverse_rec              // x0 = rest (new head of the reversed tail)
    ldr x9, [x19, #NODE_NEXT]
    str x19, [x9, #NODE_NEXT]   // head->next->next = head
    str xzr, [x19, #NODE_NEXT]  // head->next = NULL
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
reverse_rec_base:
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
    stp x19, x20, [sp, #16]
    mov x19, #0
    mov x20, #5
main_build:
    mov x0, x19
    mov x1, x20
    bl push_front
    mov x19, x0
    subs x20, x20, #1
    b.ne main_build

    adrp x0, lbl_before@PAGE
    add x0, x0, lbl_before@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    bl reverse_rec
    mov x19, x0
    adrp x0, lbl_after@PAGE
    add x0, x0, lbl_after@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    bl free_list
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt_item:   .asciz " %ld"
lbl_before: .asciz "before:"
lbl_after:  .asciz "reversed:"
msg_oom:    .asciz "out of memory"
