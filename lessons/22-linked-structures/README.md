# Lesson 22: Linked structures

## Goals

After this lesson you can:

- Describe a node struct in assembly with `.equ` offsets and allocate nodes with `malloc`.
- Build a singly linked list and write push front, append, find, remove,
  reverse, and free-all.
- Build a stack and a queue out of linked nodes.
- Build a binary search tree and write insert, search, in-order traversal,
  height, and free.
- Choose between recursion and a loop for walking a linked structure, and
  explain what each costs.

## Before you start

You need:

- [Lesson 15](../15-calling-convention/): callee-saved registers and recursion.
- [Lesson 19](../19-structs-and-unions/): struct layout and `.equ` offsets.
- [Lesson 21](../21-the-heap/): `malloc`, `free`, checking for `NULL`, ownership.

All the examples are in [linux/examples/](linux/examples/). Build them once now:

```console
$ cd lessons/22-linked-structures/linux/examples
$ make
```

## Why link things together?

An array keeps its elements side by side in one block of memory. That makes
indexing fast (`a[i]` is one address calculation), but it makes two things
awkward:

- Inserting in the middle means sliding every later element along.
- Growing means `realloc`, which may copy the whole array (lesson 21).

A *linked* structure keeps each element in its own small heap block, called a
**node**. Each node holds a value and the *address* of the next node. To insert,
you allocate one node and change a couple of pointers. Nothing else moves.

The price: there is no `a[i]`. To reach the fifth node you must start at the
first one and follow four pointers.

Here is a list holding 30, 20, 10. Each box is a separate `malloc` block; the
addresses are made up but realistic:

```
  head
  0x4a2e0          0x4a2e0             0x4a2c0             0x4a2a0
  +-------+        +------+---------+  +------+---------+  +------+---------+
  |0x4a2e0| -----> |  30  | 0x4a2c0 |->|  20  | 0x4a2a0 |->|  10  |    0    |
  +-------+        +------+---------+  +------+---------+  +------+---------+
                    value   next        value   next        value   next
```

`head` is just a 64-bit variable holding the address of the first node. The
last node's `next` is 0, which is `NULL`: "there is no next node". An empty
list is `head == NULL`.

## The node struct

In C:

```c
struct node {
    long value;          // offset 0, 8 bytes
    struct node *next;   // offset 8, 8 bytes
};                       // sizeof = 16
```

Both fields are 8 bytes, so there is no padding (lesson 19). In assembly you
name the offsets with `.equ` so your code says what it means:

```asm
    .equ NODE_VALUE, 0          // offsetof(struct node, value)
    .equ NODE_NEXT,  8          // offsetof(struct node, next)
    .equ NODE_SIZE,  16         // sizeof(struct node)
```

With a node's address in `x0`:

| C | Assembly |
|---|----------|
| `n->value` | `ldr x1, [x0, #NODE_VALUE]` |
| `n->next` | `ldr x1, [x0, #NODE_NEXT]` |
| `n->next = NULL` | `str xzr, [x0, #NODE_NEXT]` |
| `p = p->next` | `ldr x0, [x0, #NODE_NEXT]` |

That last line is the heart of every list walk: load the next pointer into the
same register that held the current pointer.

## Building a list: push front

The easiest place to add a node is the front. In C:

```c
struct node *push_front(struct node *head, long value) {
    struct node *n = malloc(sizeof(struct node));
    if (n == NULL) out_of_memory();
    n->value = value;
    n->next = head;        // the new node points at the old first node
    return n;              // and becomes the new first node
}

head = push_front(head, 10);
```

The function returns the new head and the caller stores it. This
"`head = f(head, ...)`" style is used for every operation in this lesson that
might change which node is first.

In assembly ([linux/examples/list_basics.s](linux/examples/list_basics.s)):

```asm
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
```

Why `x19` and `x20`? `malloc` is a normal function: it may overwrite any of `x0`-`x17`. The head and value must
survive the call, so they go in callee-saved registers, which we save and
restore (lesson 15).

`out_of_memory` is a small piece of code that prints a message and calls
`exit(1)`. It never returns, so jumping to it with `cbz` (instead of calling it
with `bl`) is fine. Real programs often do exactly this.

Draw it. Start with `head = NULL` and push 10, then 20, then 30:

```
after push 10:  head -> [10|NULL]
after push 20:  head -> [20| *]-> [10|NULL]
after push 30:  head -> [30| *]-> [20| *]-> [10|NULL]
```

Pushing at the front reverses the order you pushed in.

## Walking a list

To visit every node, you follow `next` until you hit `NULL`:

```c
long list_length(struct node *p) {
    long count = 0;
    while (p != NULL) {
        count++;
        p = p->next;
    }
    return count;
}
```

```asm
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
```

`cbz` is perfect for "is this pointer NULL?". This function calls nothing, so it
is a leaf and needs no frame at all.

`print_list` is the same loop with a `printf(" %ld", p->value)` in the middle.
Because it calls `printf`, `p` has to live in `x19`. It ends the line with
`putchar('\n')`: `putchar(c)` prints one character, and `10` is the ASCII code
of newline.

## Freeing a list

Every node came from `malloc`, so every node must go back to `free`. You might
write:

```c
while (p != NULL) {
    free(p);
    p = p->next;     // WRONG: p was just freed
}
```

After `free(p)` the node no longer belongs to you, so reading `p->next` is a
use-after-free (lesson 21). It might even seem to work, because `free` often
leaves most of the bytes alone, but `malloc` is allowed to reuse that memory
immediately. The fix is to read `next` *first*:

```c
while (p != NULL) {
    struct node *next = p->next;   // save it while p is still ours
    free(p);
    p = next;
}
```

```asm
free_list_loop:
    cbz x19, free_list_done
    ldr x20, [x19, #NODE_NEXT]  // next = p->next (while p is still ours)
    mov x0, x19
    bl free                     // free(p)
    mov x19, x20                // p = next
    b free_list_loop
```

`next` lives in `x20` so it survives the call to `free`.

### Try it

`main` in `list_basics.s` pushes 10, 20, 30, prints the list, prints its
length, and frees it. Before you run it, predict both lines.

```console
$ ./list_basics
list: 30 20 10
length: 3
```

## More list operations

[linux/examples/list_ops.s](linux/examples/list_ops.s) adds four more operations. Read each
one in the file as you go through this section.

### Append

Appending puts a node at the *end*. The new node's `next` is `NULL`, and the
old last node's `next` must point at it. To find the old last node you walk
until `p->next == NULL`:

```c
struct node *list_append(struct node *head, long value) {
    struct node *n = malloc(sizeof(struct node));
    if (n == NULL) out_of_memory();
    n->value = value;
    n->next = NULL;
    if (head == NULL)
        return n;                  // the list was empty: n is the head
    struct node *p = head;
    while (p->next != NULL)
        p = p->next;
    p->next = n;
    return head;
}
```

Note the special case: if the list is empty there *is* no last node, and the new
node becomes the head. Forgetting the empty case is the most common list bug.

```asm
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
```

The walk calls nothing, so `x9` and `x10` (temporaries) are safe to use.

Appending this way walks the whole list every time: appending *n* items costs
about *n*²/2 steps. The queue below fixes that by remembering the last node.

### Find

```c
struct node *list_find(struct node *p, long value) {
    while (p != NULL && p->value != value)
        p = p->next;
    return p;                      // the node, or NULL if not found
}
```

```asm
list_find:
    cbz x0, list_find_done      // p == NULL: return NULL
    ldr x9, [x0, #NODE_VALUE]
    cmp x9, x1
    b.eq list_find_done         // p->value == value: return p
    ldr x0, [x0, #NODE_NEXT]    // p = p->next
    b list_find
list_find_done:
    ret
```

Returning the node (rather than 1 or 0) lets the caller read or change it.

### Remove

To remove a node you make the node *before* it skip over it, then free it.
So you walk with two pointers: `cur`, and `prev` one step behind:

```
before:  head -> [1]-> [2]-> [3]-> NULL        remove 2
                  prev   cur
after:   head -> [1]--------> [3]-> NULL       prev->next = cur->next; free(cur)
```

If the node to remove is the first one, there is no `prev`; instead `head`
itself changes. That is why `list_remove` returns the head:

```c
struct node *list_remove(struct node *head, long value) {
    struct node *prev = NULL, *cur = head;
    while (cur != NULL && cur->value != value) {
        prev = cur;
        cur = cur->next;
    }
    if (cur == NULL)
        return head;               // not found: nothing to do
    if (prev == NULL)
        head = cur->next;          // removing the first node
    else
        prev->next = cur->next;    // removing a later node
    free(cur);
    return head;
}
```

```asm
list_remove_found:
    ldr x11, [x10, #NODE_NEXT]  // x11 = cur->next
    cbz x9, list_remove_first
    str x11, [x9, #NODE_NEXT]   // prev->next = cur->next
    b list_remove_free
list_remove_first:
    mov x19, x11                // removing the head: head = cur->next
list_remove_free:
    mov x0, x10
    bl free                     // free(cur) - nothing points to it now
```

Order matters here too: unlink first, free second, and read `cur->next` before
`free`.

### Reverse

Reversing a list in place turns every arrow around. You need three pointers:
`prev` (the already-reversed part), `cur`, and `next` (so you don't lose the rest
of the list when you overwrite `cur->next`):

```c
struct node *list_reverse(struct node *cur) {
    struct node *prev = NULL;
    while (cur != NULL) {
        struct node *next = cur->next;
        cur->next = prev;
        prev = cur;
        cur = next;
    }
    return prev;
}
```

Trace it on 1 -> 2 -> 3:

| step | prev | cur | list as seen from prev |
|------|------|-----|------------------------|
| start | NULL | 1 | (empty) |
| 1 | 1 | 2 | 1 -> NULL |
| 2 | 2 | 3 | 2 -> 1 -> NULL |
| 3 | 3 | NULL | 3 -> 2 -> 1 -> NULL |

```asm
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
```

No `malloc`, no `free`: the same nodes, new arrows.

### Try it

`main` appends 1 to 5, looks for 3 and 9, removes 1 (the head), 4 (the middle)
and 9 (not there), then reverses. Predict every line, then:

```console
$ ./list_ops
built: 1 2 3 4 5
find 3: yes
find 9: no
remove 1: 2 3 4 5
remove 4: 2 3 5
remove 9: 2 3 5
reverse: 5 3 2
```

One small thing in this file: `print_list(label, head)` passes `label` straight
to `printf` as the format. That is safe only because our labels contain no `%`.
Never pass text from a user as a format string.

## Stacks and queues

A **stack** is last in, first out: you push and pop at the same end. The front
of a linked list is exactly that: push is `push_front`, pop is "remove the first
node". A **queue** is first in, first out: you add at the back and take from the
front. To add at the back without walking the list, you keep a second pointer to
the last node.

In C ([linux/examples/stack_queue.s](linux/examples/stack_queue.s)):

```c
struct stack { struct node *top; };
struct queue { struct node *head, *tail; };

void stack_push(struct stack *s, long v) {
    struct node *n = malloc(sizeof *n);   // (NULL check omitted here)
    n->value = v;
    n->next = s->top;
    s->top = n;
}

long stack_pop(struct stack *s) {         // s must not be empty
    struct node *n = s->top;
    s->top = n->next;
    long v = n->value;                    // read before free
    free(n);
    return v;
}

void queue_enqueue(struct queue *q, long v) {
    struct node *n = malloc(sizeof *n);
    n->value = v;
    n->next = NULL;
    if (q->tail != NULL) q->tail->next = n;
    else                 q->head = n;     // was empty
    q->tail = n;
}

long queue_dequeue(struct queue *q) {     // q must not be empty
    struct node *n = q->head;
    q->head = n->next;
    if (q->head == NULL) q->tail = NULL;  // now empty
    long v = n->value;
    free(n);
    return v;
}
```

The functions take a *pointer* to the stack or queue struct, because they must
change its fields (lesson 19). The structs get `.equ` offsets like any other:

```asm
    .equ STACK_TOP,  0
    .equ QUEUE_HEAD, 0
    .equ QUEUE_TAIL, 8
```

Here is the enqueue, where the empty case decides which pointer to update:

```asm
    ldr x9, [x19, #QUEUE_TAIL]
    cbz x9, queue_enqueue_empty
    str x0, [x9, #NODE_NEXT]    // q->tail->next = n
    b queue_enqueue_tail
queue_enqueue_empty:
    str x0, [x19, #QUEUE_HEAD]  // empty queue: q->head = n
queue_enqueue_tail:
    str x0, [x19, #QUEUE_TAIL]  // q->tail = n
```

`main` keeps both structs in its own stack frame (they are small, and they only
live while `main` runs) and passes their addresses with `add x0, sp, #offset`:

```asm
    .equ MAIN_STACK, 32
    .equ MAIN_QUEUE, 40
    ...
    str xzr, [sp, #MAIN_STACK + STACK_TOP]     // struct stack s = { NULL };
    ...
    add x0, sp, #MAIN_STACK                    // &s
    mov x1, x19
    bl stack_push
```

The assembler adds `MAIN_STACK + STACK_TOP` for you; offsets compose the same
way struct fields inside struct fields do.

Predict the output: push 1, 2, 3 and pop until empty; enqueue 1, 2, 3 and
dequeue until empty.

```console
$ ./stack_queue
pop: 3 2 1
dequeue: 1 2 3
```

Both pop loops stop when the structure is empty, and every pop frees its node,
so there is nothing left to free at the end.

## Recursion or a loop?

A list is a *recursive* structure: a list is either empty (`NULL`) or a node
followed by a (shorter) list. So any list walk can be written recursively.
[linux/examples/list_recursive.s](linux/examples/list_recursive.s) has the length both ways:

```c
long length_loop(struct node *p) {        long length_rec(struct node *p) {
    long n = 0;                               if (p == NULL) return 0;
    while (p) { n++; p = p->next; }           return 1 + length_rec(p->next);
    return n;                             }
}
```

```asm
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
```

Notice the base case returns *before* making a frame. That is allowed: a function
only needs a frame if it calls something.

Where recursion really helps is when the work happens *on the way back*. To print
a list backwards with a loop you would need to reverse it, or store it somewhere.
With recursion you just swap two lines:

```c
void print_forwards(struct node *p) {     void print_backwards(struct node *p) {
    if (p == NULL) return;                    if (p == NULL) return;
    printf(" %ld", p->value);                 print_backwards(p->next);
    print_forwards(p->next);                  printf(" %ld", p->value);
}                                         }
```

Each call's `p` is kept in its own saved `x19`, one per stack frame, so when the
calls return one by one, each prints its own node. The stack *is* the storage.

```console
$ ./list_recursive
forwards: 1 2 3 4
length (loop): 4
length (recursion): 4
backwards: 4 3 2 1
```

The cost: each recursive call uses a stack frame (32 bytes here). A list of a
million nodes needs a million frames, 32 MB, and the default stack on Linux is
8 MB: the program crashes with a segmentation fault. Rules of thumb:

- For a **list**, use a loop when a loop is easy (length, find, sum, free).
- For a **tree** (next section), recursion is natural, and the depth is only the
  height of the tree, not the number of nodes.

## Binary search trees

A list node has one "next". A tree node has two: `left` and `right`. In a
**binary search tree** (BST), every key in a node's left subtree is smaller than
the node's key, and every key in its right subtree is larger. Inserting
50, 30, 70, 20, 40, 60, 80, 35 in that order builds:

```
             50
           /    \
         30      70
        /  \    /  \
      20   40  60   80
          /
         35
```

To find 35: 35 < 50, go left; 35 > 30, go right; 35 < 40, go left; found. Four
steps instead of up to eight in a list. In a well-shaped tree, each step throws
away about half of what is left.

```c
struct tree {
    long key;              // offset 0
    struct tree *left;     // offset 8
    struct tree *right;    // offset 16
};                         // sizeof = 24
```

```asm
    .equ TREE_KEY,   0
    .equ TREE_LEFT,  8
    .equ TREE_RIGHT, 16
    .equ TREE_SIZE,  24
```

The code is in [linux/examples/bst.s](linux/examples/bst.s).

### Insert

Insert is easiest recursively, using the same "return the new root" trick as
the list:

```c
struct tree *bst_insert(struct tree *t, long key) {
    if (t == NULL) {                       // fell off the tree: put it here
        struct tree *n = malloc(sizeof *n);
        if (n == NULL) out_of_memory();
        n->key = key;
        n->left = n->right = NULL;
        return n;
    }
    if (key < t->key)
        t->left = bst_insert(t->left, key);
    else if (key > t->key)
        t->right = bst_insert(t->right, key);
    return t;                              // equal keys: ignore
}
```

`t->left = bst_insert(t->left, key)` looks odd but is neat: if `t->left` was
`NULL`, the call returns the new leaf and this line hooks it in; otherwise the
call returns `t->left` unchanged and the store changes nothing.

```asm
bst_insert_descend:
    ldr x9, [x19, #TREE_KEY]
    cmp x20, x9
    b.lt bst_insert_left
    b.gt bst_insert_right
    mov x0, x19                 // equal: nothing to do
    b bst_insert_done
bst_insert_left:
    ldr x0, [x19, #TREE_LEFT]
    mov x1, x20
    bl bst_insert
    str x0, [x19, #TREE_LEFT]   // t->left = bst_insert(t->left, key)
    mov x0, x19
    b bst_insert_done
```

Two conditional branches after one `cmp`: the flags stay set until something
changes them, so `b.lt` and `b.gt` both test the same comparison. Keys are
`long`, so the conditions are the signed ones.

### Search

Search only goes down one path, so a loop is simple and uses no stack:

```c
struct tree *bst_search(struct tree *t, long key) {
    while (t != NULL && t->key != key)
        t = key < t->key ? t->left : t->right;
    return t;
}
```

```asm
bst_search:
    cbz x0, bst_search_done
    ldr x9, [x0, #TREE_KEY]
    cmp x1, x9
    b.eq bst_search_done
    ldr x10, [x0, #TREE_LEFT]
    ldr x11, [x0, #TREE_RIGHT]
    csel x0, x10, x11, lt       // flags still from cmp key, t->key
    b bst_search
bst_search_done:
    ret
```

The `?:` becomes `csel` (lesson 10): load both children, keep one. `ldr` does
not change the flags, so `lt` still refers to the `cmp`.

### In-order traversal

"Left subtree, then this node, then right subtree" visits a BST in sorted order.
This is where recursion shines: a loop would need its own stack of nodes still
to visit.

```c
void bst_print(struct tree *t) {
    if (t == NULL) return;
    bst_print(t->left);
    printf(" %ld", t->key);
    bst_print(t->right);
}
```

```asm
bst_print:
    cbz x0, bst_print_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #TREE_LEFT]
    bl bst_print                // everything smaller first
    adrp x0, fmt_item
    add x0, x0, :lo12:fmt_item
    ldr x1, [x19, #TREE_KEY]
    bl printf                   // then this key
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_print                // then everything larger
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
bst_print_done:
    ret
```

### Height

The height is the number of nodes on the longest path from the root down
(an empty tree has height 0):

```c
long bst_height(struct tree *t) {
    if (t == NULL) return 0;
    long l = bst_height(t->left);
    long r = bst_height(t->right);
    return 1 + (l > r ? l : r);
}
```

The new problem: `l` must survive the second recursive call. It goes in `x20`,
a callee-saved register, which each level saves and restores in its own frame:

```asm
    ldr x0, [x19, #TREE_LEFT]
    bl bst_height
    mov x20, x0                 // l, kept in a callee-saved register
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_height               // x0 = r
    cmp x20, x0
    csel x0, x20, x0, gt        // max(l, r)
    add x0, x0, #1
```

### Free

To free a tree you must free both children *before* the parent, because once the
parent is freed you may not read its `left` and `right`. That order (children
first) is called **post-order**:

```c
void bst_free(struct tree *t) {
    if (t == NULL) return;
    bst_free(t->left);
    bst_free(t->right);
    free(t);
}
```

### Try it

Predict the four lines (look at the tree drawing for the height), then run:

```console
$ ./bst
in order: 20 30 35 40 50 60 70 80
height: 4
search 60: found
search 65: not found
```

The shape of a BST depends on the insertion order. Insert 1, 2, 3, ... in
sorted order and every node goes to the right: the "tree" is really a list, and
search is as slow as a list. Exercise 22.6 looks at this. (Self-balancing trees
fix it, but are beyond this lesson.)

## C to assembly

| C | Assembly |
|---|----------|
| `struct node { long value; struct node *next; };` | `.equ NODE_VALUE, 0` / `.equ NODE_NEXT, 8` / `.equ NODE_SIZE, 16` |
| `n = malloc(sizeof(struct node));` | `mov x0, #NODE_SIZE` / `bl malloc` |
| `if (n == NULL) ...` | `cbz x0, out_of_memory` |
| `n->next = NULL;` | `str xzr, [x0, #NODE_NEXT]` |
| `p = p->next;` | `ldr x0, [x0, #NODE_NEXT]` |
| `while (p != NULL) { ... }` | `loop: cbz x0, done` ... `b loop` |
| `next = p->next; free(p); p = next;` | `ldr x20, [x19, #NODE_NEXT]` / `mov x0, x19` / `bl free` / `mov x19, x20` |
| `head = push_front(head, v);` | `mov x0, x19` / `mov x1, v` / `bl push_front` / `mov x19, x0` |
| `prev->next = cur->next;` | `ldr x11, [x10, #NODE_NEXT]` / `str x11, [x9, #NODE_NEXT]` |
| `stack_push(&s, v);` (s is a local) | `add x0, sp, #MAIN_STACK` / `mov x1, v` / `bl stack_push` |
| `t = key < t->key ? t->left : t->right;` | `cmp` / `ldr` both / `csel x0, x10, x11, lt` |
| `t->left = bst_insert(t->left, key);` | `ldr x0, [x19, #TREE_LEFT]` / `bl bst_insert` / `str x0, [x19, #TREE_LEFT]` |
| `if (p == NULL) return 0;` at the top of a recursive function | `cbz x0, base` before the prologue, `base: ret` |

## Common mistakes

- **Reading a node after freeing it.** `free(p); p = p->next;` is a
  use-after-free. It often works by luck and then fails when `malloc` reuses
  the block. Read what you need first, then `free`.
- **Forgetting the empty-list case.** Append, remove, and dequeue all behave
  differently when the list is empty or has one node. If your program crashes
  with a segmentation fault on the first operation, check whether you did
  `ldr x9, [x0, #NODE_NEXT]` with `x0 == 0`. In gdb, `info registers` will show
  the base register holding 0, and the fault address will be 8 (the offset).
- **Not storing the returned head.** `bl push_front` without `mov x19, x0`
  afterwards loses the new node (a leak), and the list never changes.
- **Keeping a pointer in a temporary across a call.** `x9`-`x15` and `x0`-`x7`
  are destroyed by `malloc`, `free`, and `printf`. Pointers you still need after
  a call go in `x19`-`x28` (saved in your prologue) or in your stack frame.
- **Losing the rest of the list.** In reverse, writing `cur->next = prev`
  before saving `cur->next` cuts the list off; everything after `cur` is now
  unreachable (leaked).
- **Freeing a tree parent first.** `free(t)` before `bst_free(t->left)` reads
  freed memory. Free children first.
- **Wrong condition for the key type.** Keys here are signed `long`, so use
  `lt`/`gt`, not `lo`/`hi`. With `lo`, a key of -1 would be treated as huge.
- **Recursing over a very long list.** One stack frame per node: a long enough
  list overflows the stack and crashes. Use a loop for lists.

## Recap

- A node is a small struct on the heap; `.equ` names its field offsets.
- A list is a pointer to its first node; `NULL` means empty and ends the list.
- Walking a list is `cbz p, done` / work / `ldr p, [p, #NODE_NEXT]`.
- Functions that may change the first node return the new head; callers store it.
- Removing needs the node *before* the target; the head is a special case.
- Before `free(p)`, read anything you still need from `p`.
- A stack is push/pop at the front; a queue adds at a tail pointer and removes at
  the head.
- A BST keeps smaller keys left and larger keys right; in-order traversal prints
  them sorted; free children before parents.
- Recursion costs one stack frame per level: fine for tree height, risky for
  list length.

## Homework

[exercises.md](exercises.md). Then read the macOS companion:
[apple-silicon/](apple-silicon/).
