// list_recursive.s - the same list walks written with loops and with recursion (lesson 22, macOS)
//
// Build: make list_recursive
// Run:   ./list_recursive
// Expected output:
//   forwards: 1 2 3 4
//   length (loop): 4
//   length (recursion): 4
//   backwards: 4 3 2 1

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

    .text
    .global _main
    .p2align 2

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

// long length_loop(struct node *p)
//     long n = 0; while (p) { n++; p = p->next; } return n;
length_loop:
    mov x1, #0
length_loop_top:
    cbz x0, length_loop_done
    add x1, x1, #1
    ldr x0, [x0, #NODE_NEXT]
    b length_loop_top
length_loop_done:
    mov x0, x1
    ret

// long length_rec(struct node *p)
//     if (p == NULL) return 0;
//     return 1 + length_rec(p->next);
length_rec:
    cbz x0, length_rec_base     // base case: returns 0 (x0 is already 0)
    stp x29, x30, [sp, #-16]!   // recursive case calls, so it needs a frame
    mov x29, sp
    ldr x0, [x0, #NODE_NEXT]
    bl length_rec               // x0 = length_rec(p->next)
    add x0, x0, #1              // 1 + that
    ldp x29, x30, [sp], #16
length_rec_base:
    ret

// void print_forwards(struct node *p)
//     if (p == NULL) return;
//     printf(" %ld", p->value);  print_forwards(p->next);
print_forwards:
    cbz x0, print_forwards_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0                 // keep p: printf will clobber x0
    sub sp, sp, #16
    ldr x9, [x19, #NODE_VALUE]
    str x9, [sp]                // variadic argument goes on the stack
    adrp x0, fmt_item@PAGE
    add x0, x0, fmt_item@PAGEOFF
    bl _printf                  // first print this node...
    add sp, sp, #16
    ldr x0, [x19, #NODE_NEXT]
    bl print_forwards           // ...then the rest
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
print_forwards_done:
    ret

// void print_backwards(struct node *p)
//     if (p == NULL) return;
//     print_backwards(p->next);  printf(" %ld", p->value);
// The only change is the ORDER of the two lines.
print_backwards:
    cbz x0, print_backwards_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #NODE_NEXT]
    bl print_backwards          // first print the rest...
    sub sp, sp, #16
    ldr x9, [x19, #NODE_VALUE]
    str x9, [sp]                // variadic argument goes on the stack
    adrp x0, fmt_item@PAGE
    add x0, x0, fmt_item@PAGEOFF
    bl _printf                  // ...then this node
    add sp, sp, #16
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
print_backwards_done:
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
    stp x19, x20, [sp, #16]     // x19 = head, x20 = i

    mov x19, #0
    mov x20, #4
main_build:                     // for (i = 4; i >= 1; i--) head = push_front(head, i);
    mov x0, x19
    mov x1, x20
    bl push_front
    mov x19, x0
    subs x20, x20, #1
    b.ne main_build             // the list is now 1 2 3 4

    adrp x0, msg_fwd@PAGE
    add x0, x0, msg_fwd@PAGEOFF
    bl _printf
    mov x0, x19
    bl print_forwards
    mov w0, #10
    bl _putchar

    mov x0, x19
    bl length_loop
    sub sp, sp, #16
    str x0, [sp]                // variadic argument goes on the stack
    adrp x0, fmt_len_loop@PAGE
    add x0, x0, fmt_len_loop@PAGEOFF
    bl _printf
    add sp, sp, #16

    mov x0, x19
    bl length_rec
    sub sp, sp, #16
    str x0, [sp]                // variadic argument goes on the stack
    adrp x0, fmt_len_rec@PAGE
    add x0, x0, fmt_len_rec@PAGEOFF
    bl _printf
    add sp, sp, #16

    adrp x0, msg_back@PAGE
    add x0, x0, msg_back@PAGEOFF
    bl _printf
    mov x0, x19
    bl print_backwards
    mov w0, #10
    bl _putchar

    mov x0, x19
    bl free_list
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt_item:     .asciz " %ld"
msg_fwd:      .asciz "forwards:"
msg_back:     .asciz "backwards:"
fmt_len_loop: .asciz "length (loop): %ld\n"
fmt_len_rec:  .asciz "length (recursion): %ld\n"
msg_oom:      .asciz "out of memory"
