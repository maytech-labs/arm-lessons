// list_basics.s - build a linked list with push_front, print it, free it (lesson 22)
//
// Build: make list_basics
// Run:   ./list_basics
// Expected output:
//   list: 30 20 10
//   length: 3
//
// The C version:
//   struct node { long value; struct node *next; };
//   struct node *head = NULL;
//   head = push_front(head, 10);
//   head = push_front(head, 20);
//   head = push_front(head, 30);
//   print_list(head);
//   printf("length: %ld\n", list_length(head));
//   free_list(head);

// struct node { long value; struct node *next; };
    .equ NODE_VALUE, 0          // offsetof(struct node, value)
    .equ NODE_NEXT,  8          // offsetof(struct node, next)
    .equ NODE_SIZE,  16         // sizeof(struct node)

    .text
    .global main
    .p2align 2

// struct node *push_front(struct node *head, long value)
// Makes a new node in front of head and returns it (the new head).
push_front:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // x19 = old head
    mov x20, x1                 // x20 = value
    mov x0, #NODE_SIZE
    bl malloc                   // x0 = malloc(sizeof(struct node))
    cbz x0, out_of_memory       // NULL: give up
    str x20, [x0, #NODE_VALUE]  // n->value = value
    str x19, [x0, #NODE_NEXT]   // n->next = old head
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret                         // return n

// void print_list(struct node *head)
// Prints "list:" and then " value" for every node, then a newline.
print_list:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                 // x19 = p = head
    adrp x0, msg_list
    add x0, x0, :lo12:msg_list
    bl printf                   // printf("list:")
print_list_loop:
    cbz x19, print_list_done    // while (p != NULL)
    adrp x0, fmt_item
    add x0, x0, :lo12:fmt_item
    ldr x1, [x19, #NODE_VALUE]
    bl printf                   //     printf(" %ld", p->value)
    ldr x19, [x19, #NODE_NEXT]  //     p = p->next
    b print_list_loop
print_list_done:
    mov w0, #10                 // '\n'
    bl putchar
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// long list_length(struct node *head)
// A leaf function: it calls nothing, so it needs no frame.
list_length:
    mov x1, #0                  // count = 0
list_length_loop:
    cbz x0, list_length_done    // while (p != NULL)
    add x1, x1, #1              //     count++
    ldr x0, [x0, #NODE_NEXT]    //     p = p->next
    b list_length_loop
list_length_done:
    mov x0, x1
    ret

// void free_list(struct node *head)
// Frees every node. It must read p->next BEFORE freeing p.
free_list:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // x19 = p
free_list_loop:
    cbz x19, free_list_done
    ldr x20, [x19, #NODE_NEXT]  // next = p->next (while p is still ours)
    mov x0, x19
    bl free                     // free(p)
    mov x19, x20                // p = next
    b free_list_loop
free_list_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// Called (by branch) when malloc returns NULL: print a message, exit(1).
out_of_memory:
    adrp x0, msg_oom
    add x0, x0, :lo12:msg_oom
    bl puts
    mov w0, #1
    bl exit

main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]          // x19 = head, kept across calls

    mov x19, #0                 // head = NULL (the empty list)
    mov x0, x19
    mov x1, #10
    bl push_front
    mov x19, x0                 // head = push_front(head, 10)
    mov x0, x19
    mov x1, #20
    bl push_front
    mov x19, x0                 // head = push_front(head, 20)
    mov x0, x19
    mov x1, #30
    bl push_front
    mov x19, x0                 // head = push_front(head, 30)

    mov x0, x19
    bl print_list

    mov x0, x19
    bl list_length
    mov x1, x0
    adrp x0, fmt_len
    add x0, x0, :lo12:fmt_len
    bl printf                   // printf("length: %ld\n", list_length(head))

    mov x0, x19
    bl free_list                // free_list(head)

    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
msg_list: .asciz "list:"
fmt_item: .asciz " %ld"
fmt_len:  .asciz "length: %ld\n"
msg_oom:  .asciz "out of memory"
