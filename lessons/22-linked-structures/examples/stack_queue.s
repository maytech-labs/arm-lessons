// stack_queue.s - a stack and a queue built from linked nodes (lesson 22)
//
// Build: make stack_queue
// Run:   ./stack_queue
// Expected output:
//   pop: 3 2 1
//   dequeue: 1 2 3
//
// Push 1, 2, 3 on a stack and pop them back: last in, first out.
// Enqueue 1, 2, 3 on a queue and dequeue them: first in, first out.

    .equ NODE_VALUE, 0
    .equ NODE_NEXT,  8
    .equ NODE_SIZE,  16

// struct stack { struct node *top; };
    .equ STACK_TOP,  0

// struct queue { struct node *head; struct node *tail; };
    .equ QUEUE_HEAD, 0          // dequeue from here
    .equ QUEUE_TAIL, 8          // enqueue here

    .text
    .global main
    .p2align 2

// void stack_push(struct stack *s, long value)
stack_push:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // s
    mov x20, x1                 // value
    mov x0, #NODE_SIZE
    bl malloc
    cbz x0, out_of_memory
    str x20, [x0, #NODE_VALUE]  // n->value = value
    ldr x9, [x19, #STACK_TOP]
    str x9, [x0, #NODE_NEXT]    // n->next = s->top
    str x0, [x19, #STACK_TOP]   // s->top = n
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// long stack_pop(struct stack *s)     (s must not be empty)
stack_pop:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    ldr x1, [x0, #STACK_TOP]    // n = s->top
    ldr x9, [x1, #NODE_NEXT]
    str x9, [x0, #STACK_TOP]    // s->top = n->next
    ldr x19, [x1, #NODE_VALUE]  // value = n->value (read before free!)
    mov x0, x1
    bl free                     // free(n)
    mov x0, x19                 // return value
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// void queue_enqueue(struct queue *q, long value)
queue_enqueue:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // q
    mov x20, x1                 // value
    mov x0, #NODE_SIZE
    bl malloc
    cbz x0, out_of_memory
    str x20, [x0, #NODE_VALUE]  // n->value = value
    str xzr, [x0, #NODE_NEXT]   // n->next = NULL
    ldr x9, [x19, #QUEUE_TAIL]
    cbz x9, queue_enqueue_empty
    str x0, [x9, #NODE_NEXT]    // q->tail->next = n
    b queue_enqueue_tail
queue_enqueue_empty:
    str x0, [x19, #QUEUE_HEAD]  // empty queue: q->head = n
queue_enqueue_tail:
    str x0, [x19, #QUEUE_TAIL]  // q->tail = n
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// long queue_dequeue(struct queue *q)     (q must not be empty)
queue_dequeue:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    ldr x1, [x0, #QUEUE_HEAD]   // n = q->head
    ldr x9, [x1, #NODE_NEXT]
    str x9, [x0, #QUEUE_HEAD]   // q->head = n->next
    cbnz x9, queue_dequeue_free
    str xzr, [x0, #QUEUE_TAIL]  // queue now empty: q->tail = NULL too
queue_dequeue_free:
    ldr x19, [x1, #NODE_VALUE]  // value = n->value
    mov x0, x1
    bl free
    mov x0, x19
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

out_of_memory:
    adrp x0, msg_oom
    add x0, x0, :lo12:msg_oom
    bl puts
    mov w0, #1
    bl exit

// Stack frame of main:
//   [sp, #0]  saved x29, x30
//   [sp, #16] saved x19, x20
//   [sp, #32] struct stack s      (8 bytes)
//   [sp, #40] struct queue q      (16 bytes)
//   [sp, #56] padding to keep the frame a multiple of 16
    .equ MAIN_STACK, 32
    .equ MAIN_QUEUE, 40

main:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str xzr, [sp, #MAIN_STACK + STACK_TOP]     // struct stack s = { NULL };
    str xzr, [sp, #MAIN_QUEUE + QUEUE_HEAD]    // struct queue q = { NULL, NULL };
    str xzr, [sp, #MAIN_QUEUE + QUEUE_TAIL]

    // ---- stack ----
    mov x19, #1
main_push:                      // for (i = 1; i <= 3; i++) stack_push(&s, i);
    add x0, sp, #MAIN_STACK
    mov x1, x19
    bl stack_push
    add x19, x19, #1
    cmp x19, #3
    b.le main_push

    adrp x0, msg_pop
    add x0, x0, :lo12:msg_pop
    bl printf
main_pop:                       // while (s.top != NULL) printf(" %ld", stack_pop(&s));
    ldr x9, [sp, #MAIN_STACK + STACK_TOP]
    cbz x9, main_pop_done
    add x0, sp, #MAIN_STACK
    bl stack_pop
    mov x1, x0
    adrp x0, fmt_item
    add x0, x0, :lo12:fmt_item
    bl printf
    b main_pop
main_pop_done:
    mov w0, #10
    bl putchar

    // ---- queue ----
    mov x19, #1
main_enq:                       // for (i = 1; i <= 3; i++) queue_enqueue(&q, i);
    add x0, sp, #MAIN_QUEUE
    mov x1, x19
    bl queue_enqueue
    add x19, x19, #1
    cmp x19, #3
    b.le main_enq

    adrp x0, msg_deq
    add x0, x0, :lo12:msg_deq
    bl printf
main_deq:                       // while (q.head != NULL) printf(" %ld", queue_dequeue(&q));
    ldr x9, [sp, #MAIN_QUEUE + QUEUE_HEAD]
    cbz x9, main_deq_done
    add x0, sp, #MAIN_QUEUE
    bl queue_dequeue
    mov x1, x0
    adrp x0, fmt_item
    add x0, x0, :lo12:fmt_item
    bl printf
    b main_deq
main_deq_done:
    mov w0, #10
    bl putchar

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

    .section .rodata
fmt_item: .asciz " %ld"
msg_pop:  .asciz "pop:"
msg_deq:  .asciz "dequeue:"
msg_oom:  .asciz "out of memory"
