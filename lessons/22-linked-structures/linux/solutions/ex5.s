// ex5.s - remove every node holding a value, using a pointer to a pointer (lesson 22, exercise 22.5)
//
// Build: make ex5
// Run:   ./ex5
// Expected output:
//   before: 1 2 1 3 1
//   after removing 1: 2 3
//   after removing 2 and 3:

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

    .text
    .global main
    .p2align 2

// struct node *remove_all(struct node *head, long value)
//     struct node **link = &head;          // the pointer we may rewrite
//     while (*link != NULL) {
//         struct node *n = *link;
//         if (n->value == value) { *link = n->next; free(n); }
//         else link = &n->next;
//     }
//     return head;
// head lives in our stack frame so that it has an address (&head).
remove_all:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]     // x19 = link, x20 = value
    str x0, [sp, #32]           // head, in memory
    add x19, sp, #32            // link = &head
    mov x20, x1
remove_all_loop:
    ldr x0, [x19]               // n = *link
    cbz x0, remove_all_done
    ldr x9, [x0, #NODE_VALUE]
    cmp x9, x20
    b.ne remove_all_skip
    ldr x9, [x0, #NODE_NEXT]
    str x9, [x19]               // *link = n->next
    bl free                     // free(n); x0 is still n
    b remove_all_loop           // link stays put: check the node that moved up
remove_all_skip:
    add x19, x0, #NODE_NEXT     // link = &n->next
    b remove_all_loop
remove_all_done:
    ldr x0, [sp, #32]           // return head (maybe rewritten through link)
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// struct node *push_front(struct node *head, long value)
push_front:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
    mov x0, #NODE_SIZE
    bl malloc
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
    bl printf                   // printf(label)
print_list_loop:
    cbz x19, print_list_done
    adrp x0, fmt_item
    add x0, x0, :lo12:fmt_item
    ldr x1, [x19, #NODE_VALUE]
    bl printf
    ldr x19, [x19, #NODE_NEXT]
    b print_list_loop
print_list_done:
    mov w0, #10
    bl putchar
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
    bl free
    mov x19, x20
    b free_list_loop
free_list_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

out_of_memory:
    adrp x0, msg_oom
    add x0, x0, :lo12:msg_oom
    bl puts
    mov w0, #1
    bl exit

main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x0, #0                  // build 1 2 1 3 1 back to front
    mov x1, #1
    bl push_front
    mov x1, #3
    bl push_front
    mov x1, #1
    bl push_front
    mov x1, #2
    bl push_front
    mov x1, #1
    bl push_front
    mov x19, x0

    adrp x0, lbl_before
    add x0, x0, :lo12:lbl_before
    mov x1, x19
    bl print_list

    mov x0, x19
    mov x1, #1
    bl remove_all
    mov x19, x0
    adrp x0, lbl_after1
    add x0, x0, :lo12:lbl_after1
    mov x1, x19
    bl print_list

    mov x0, x19
    mov x1, #2
    bl remove_all
    mov x1, #3
    bl remove_all
    mov x19, x0                 // now NULL: the empty list
    adrp x0, lbl_after23
    add x0, x0, :lo12:lbl_after23
    mov x1, x19
    bl print_list

    mov x0, x19
    bl free_list                // freeing NULL is fine: the loop never runs
    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
fmt_item:    .asciz " %ld"
lbl_before:  .asciz "before:"
lbl_after1:  .asciz "after removing 1:"
lbl_after23: .asciz "after removing 2 and 3:"
msg_oom:     .asciz "out of memory"
