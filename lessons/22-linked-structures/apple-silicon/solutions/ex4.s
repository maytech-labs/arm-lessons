// ex4.s - insert into a list so it stays sorted (lesson 22, exercise 22.4, macOS)
//
// Build: make ex4
// Run:   ./ex4
// Expected output:
//   sorted: 1 2 3 4 5

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

    .equ NVALUES, 5             // how many entries the values table has

    .text
    .global _main
    .p2align 2

// struct node *insert_sorted(struct node *head, long value)
//     n = malloc(...); n->value = value;
//     if (head == NULL || value <= head->value) { n->next = head; return n; }
//     p = head;
//     while (p->next != NULL && p->next->value < value) p = p->next;
//     n->next = p->next; p->next = n;
//     return head;
insert_sorted:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // head
    mov x20, x1                 // value
    mov x0, #NODE_SIZE
    bl _malloc
    cbz x0, out_of_memory
    str x20, [x0, #NODE_VALUE]
    cbz x19, insert_sorted_front
    ldr x9, [x19, #NODE_VALUE]
    cmp x20, x9
    b.le insert_sorted_front
    mov x9, x19                 // p = head
insert_sorted_walk:
    ldr x10, [x9, #NODE_NEXT]   // q = p->next
    cbz x10, insert_sorted_link
    ldr x11, [x10, #NODE_VALUE]
    cmp x11, x20
    b.ge insert_sorted_link     // stop when q->value >= value
    mov x9, x10
    b insert_sorted_walk
insert_sorted_link:
    str x10, [x0, #NODE_NEXT]   // n->next = p->next
    str x0, [x9, #NODE_NEXT]    // p->next = n
    mov x0, x19                 // return head
    b insert_sorted_done
insert_sorted_front:
    str x19, [x0, #NODE_NEXT]   // n->next = head; return n
insert_sorted_done:
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
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, #0                 // head
    adrp x21, values@PAGE
    add x21, x21, values@PAGEOFF
    mov x20, #0
main_loop:
    mov x0, x19
    ldr x1, [x21, x20, lsl #3]
    bl insert_sorted
    mov x19, x0
    add x20, x20, #1
    cmp x20, #NVALUES
    b.lo main_loop

    adrp x0, lbl_sorted@PAGE
    add x0, x0, lbl_sorted@PAGEOFF
    mov x1, x19
    bl print_list
    mov x0, x19
    bl free_list
    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section __TEXT,__const
    .p2align 3
values:     .quad 5, 1, 4, 2, 3
    .section __TEXT,__cstring
fmt_item:   .asciz " %ld"
lbl_sorted: .asciz "sorted:"
msg_oom:    .asciz "out of memory"
