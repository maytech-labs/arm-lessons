// list_ops.s - append, find, remove and reverse on a linked list (lesson 22, macOS)
//
// Build: make list_ops
// Run:   ./list_ops
// Expected output:
//   built: 1 2 3 4 5
//   find 3: yes
//   find 9: no
//   remove 1: 2 3 4 5
//   remove 4: 2 3 5
//   remove 9: 2 3 5
//   reverse: 5 3 2

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

    .text
    .global _main
    .p2align 2

// struct node *list_append(struct node *head, long value)
// Adds a node at the END. Returns the head (which only changes if the
// list was empty).
list_append:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // x19 = head
    mov x20, x1                 // x20 = value
    mov x0, #NODE_SIZE
    bl _malloc
    cbz x0, out_of_memory
    str x20, [x0, #NODE_VALUE]  // n->value = value
    str xzr, [x0, #NODE_NEXT]   // n->next = NULL (it will be the last node)
    cbz x19, list_append_done   // empty list: n is the new head, x0 = n
    mov x9, x19                 // p = head
list_append_walk:
    ldr x10, [x9, #NODE_NEXT]   // while (p->next != NULL)
    cbz x10, list_append_link
    mov x9, x10                 //     p = p->next
    b list_append_walk
list_append_link:
    str x0, [x9, #NODE_NEXT]    // p->next = n
    mov x0, x19                 // return head (unchanged)
list_append_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// struct node *list_find(struct node *head, long value)
// Returns the first node holding value, or NULL. Leaf function.
list_find:
    cbz x0, list_find_done      // p == NULL: return NULL
    ldr x9, [x0, #NODE_VALUE]
    cmp x9, x1
    b.eq list_find_done         // p->value == value: return p
    ldr x0, [x0, #NODE_NEXT]    // p = p->next
    b list_find
list_find_done:
    ret

// struct node *list_remove(struct node *head, long value)
// Unlinks and frees the first node holding value. Returns the new head.
list_remove:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                 // x19 = head, our return value
    mov x9, #0                  // prev = NULL
    mov x10, x0                 // cur = head
list_remove_loop:
    cbz x10, list_remove_done   // ran off the end: value not in the list
    ldr x11, [x10, #NODE_VALUE]
    cmp x11, x1
    b.eq list_remove_found
    mov x9, x10                 // prev = cur
    ldr x10, [x10, #NODE_NEXT]  // cur = cur->next
    b list_remove_loop
list_remove_found:
    ldr x11, [x10, #NODE_NEXT]  // x11 = cur->next
    cbz x9, list_remove_first
    str x11, [x9, #NODE_NEXT]   // prev->next = cur->next
    b list_remove_free
list_remove_first:
    mov x19, x11                // removing the head: head = cur->next
list_remove_free:
    mov x0, x10
    bl _free                    // free(cur) - nothing points to it now
list_remove_done:
    mov x0, x19
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// struct node *list_reverse(struct node *head)
// Reverses the list in place by turning every next pointer around.
list_reverse:
    mov x9, #0                  // prev = NULL
list_reverse_loop:
    cbz x0, list_reverse_done   // while (cur != NULL)
    ldr x10, [x0, #NODE_NEXT]   //     next = cur->next
    str x9, [x0, #NODE_NEXT]    //     cur->next = prev
    mov x9, x0                  //     prev = cur
    mov x0, x10                 //     cur = next
    b list_reverse_loop
list_reverse_done:
    mov x0, x9                  // prev is the new head
    ret

// void print_list(const char *label, struct node *head)
// label contains no '%', so it is safe to pass straight to printf.
print_list:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x1                 // x19 = p = head
    bl _printf                  // printf(label)
print_list_loop:
    cbz x19, print_list_done
    adrp x0, fmt_item@PAGE
    add x0, x0, fmt_item@PAGEOFF
    sub sp, sp, #16
    ldr x9, [x19, #NODE_VALUE]
    str x9, [sp]                // variadic argument goes on the stack
    bl _printf                  // printf(" %ld", p->value)
    add sp, sp, #16
    ldr x19, [x19, #NODE_NEXT]
    b print_list_loop
print_list_done:
    mov w0, #10
    bl _putchar                 // putchar('\n')
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
    ldr x20, [x19, #NODE_NEXT]  // save next before free
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

// void report_find(const char *label, struct node *head, long value)
// Prints label, then "yes" or "no".
report_find:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x1                 // head
    mov x20, x2                 // value
    bl _printf                  // printf(label)
    mov x0, x19
    mov x1, x20
    bl list_find
    adrp x9, msg_yes@PAGE
    add x9, x9, msg_yes@PAGEOFF
    adrp x10, msg_no@PAGE
    add x10, x10, msg_no@PAGEOFF
    cmp x0, #0
    csel x0, x9, x10, ne        // found ? "yes" : "no"
    bl _puts
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]     // x19 = head, x20 = loop counter

    mov x19, #0                 // head = NULL
    mov x20, #1
main_build:                     // for (i = 1; i <= 5; i++)
    mov x0, x19
    mov x1, x20
    bl list_append
    mov x19, x0                 //     head = list_append(head, i)
    add x20, x20, #1
    cmp x20, #5
    b.le main_build

    adrp x0, lbl_built@PAGE
    add x0, x0, lbl_built@PAGEOFF
    mov x1, x19
    bl print_list

    adrp x0, lbl_find3@PAGE
    add x0, x0, lbl_find3@PAGEOFF
    mov x1, x19
    mov x2, #3
    bl report_find
    adrp x0, lbl_find9@PAGE
    add x0, x0, lbl_find9@PAGEOFF
    mov x1, x19
    mov x2, #9
    bl report_find

    mov x0, x19
    mov x1, #1
    bl list_remove              // remove the head
    mov x19, x0
    adrp x0, lbl_rm1@PAGE
    add x0, x0, lbl_rm1@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    mov x1, #4
    bl list_remove              // remove from the middle
    mov x19, x0
    adrp x0, lbl_rm4@PAGE
    add x0, x0, lbl_rm4@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    mov x1, #9
    bl list_remove              // not there: nothing changes
    mov x19, x0
    adrp x0, lbl_rm9@PAGE
    add x0, x0, lbl_rm9@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    bl list_reverse
    mov x19, x0
    adrp x0, lbl_rev@PAGE
    add x0, x0, lbl_rev@PAGEOFF
    mov x1, x19
    bl print_list

    mov x0, x19
    bl free_list

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt_item:  .asciz " %ld"
msg_yes:   .asciz "yes"
msg_no:    .asciz "no"
msg_oom:   .asciz "out of memory"
lbl_built: .asciz "built:"
lbl_find3: .asciz "find 3: "
lbl_find9: .asciz "find 9: "
lbl_rm1:   .asciz "remove 1:"
lbl_rm4:   .asciz "remove 4:"
lbl_rm9:   .asciz "remove 9:"
lbl_rev:   .asciz "reverse:"
