# Lesson 22 exercises

Work in a `work/` directory inside this lesson's `linux/` folder (on macOS: `apple-silicon/`) (it is git-ignored):

```console
$ mkdir -p lessons/22-linked-structures/work
$ cd lessons/22-linked-structures/work
$ cp ../examples/Makefile .        # builds every .s file here
```

Copy the helper functions you need (`push_front`, `print_list`, `free_list`,
`out_of_memory`, `bst_insert`, ...) from the examples into your own files: each
program must be a single self-contained `.s` file.

Try every exercise yourself before looking. Programming solutions are in
[linux/solutions/](linux/solutions/) as `exK.s`; written answers are in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 22.1 [warm-up]

A program starts with `head = NULL` and calls `head = push_front(head, 5)`, then
`push_front(head, 6)` (and stores the result), then `push_front(head, 7)` (and
stores the result). `malloc` returns these addresses, in order: `0x1000`,
`0x1020`, `0x1040`.

1. Draw the list: every node's address, `value`, and `next`.
2. What does `head` hold?
3. What is `head->next->next->value`?
4. What is in the 8 bytes at address `0x1028`? (Hint: `NODE_NEXT` is 8.)
5. What does `print_list` print?

## Exercise 22.2 [warm-up]

Someone writes `free_list` like this:

```asm
free_list_loop:
    cbz x19, free_list_done
    mov x0, x19
    bl free
    ldr x19, [x19, #NODE_NEXT]
    b free_list_loop
```

1. What is wrong with it? Which C line does it correspond to?
2. Why might it seem to work when you test it?
3. Fix it, changing as little as possible.

## Exercise 22.3 [core]

Write `ex3.s`. It contains two leaf functions:

- `long list_sum(struct node *p)`: the sum of all values (0 for an empty list).
- `long list_max(struct node *p)`: the largest value; `p` is never `NULL`.

`main` builds the list `4 -2 9 7` with `push_front` (push 7 first), prints it
with `print_list`, prints the sum and the maximum, and frees the list.

Expected output:

```
list: 4 -2 9 7
sum: 18
max: 9
```

Which condition did you use in `list_max`, and why does it matter for this list?

## Exercise 22.4 [core]

Write `ex4.s` with `struct node *insert_sorted(struct node *head, long value)`,
which inserts a new node so the list stays in ascending order and returns the
head. `main` inserts the values 5, 1, 4, 2, 3 (from a `.quad` table) into an
empty list, prints it, and frees it.

Expected output:

```
sorted: 1 2 3 4 5
```

Hint: there are two cases. Either the new node goes first (the list is empty, or
`value <= head->value`), or you walk with `p` until `p->next` is `NULL` or holds
a value `>= value`, and insert after `p`.

## Exercise 22.5 [core]

Write `ex5.s` with `struct node *remove_all(struct node *head, long value)`,
which removes and frees *every* node holding `value` and returns the new head.

Use this C as your plan. It uses a pointer to a pointer, which removes the
special case for the head:

```c
struct node *remove_all(struct node *head, long value) {
    struct node **link = &head;      // the pointer we may need to rewrite
    while (*link != NULL) {
        struct node *n = *link;
        if (n->value == value) {
            *link = n->next;         // unlink n (this may change head itself)
            free(n);
        } else {
            link = &n->next;         // move on to n's next field
        }
    }
    return head;
}
```

`head` needs an address, so store it in your stack frame and point `link` at
that slot (`add x19, sp, #32`). `&n->next` is `n + NODE_NEXT`, which is one
`add`.

`main` builds `1 2 1 3 1`, prints it, removes all 1s, prints, removes all 2s and
all 3s, prints the (now empty) list, and frees it.

Expected output:

```
before: 1 2 1 3 1
after removing 1: 2 3
after removing 2 and 3:
```

## Exercise 22.6 [core]

Written. Think about a BST built with `bst_insert` from `examples/bst.s`.

1. You insert 1, 2, 3, 4, 5, 6, 7 in that order. Draw the tree. What is its
   height? How many comparisons does searching for 7 take?
2. Give an insertion order of the same seven keys that makes a tree of height 3.
3. How many stack frames deep does `bst_print` go on the tree from question 1?
   On your tree from question 2?
4. `bst_search` is a loop but `bst_print` is recursive. Why is that a sensible
   split?

## Exercise 22.7 [core]

Write `ex7.s` with three BST functions:

- `long bst_count(struct tree *t)`: the number of nodes (recursive).
- `long bst_min(struct tree *t)`: the smallest key (a loop: keep going left).
- `long bst_max(struct tree *t)`: the largest key (a loop: keep going right).

`bst_min` and `bst_max` may assume `t != NULL`. `main` builds the tree from
`50, 30, 70, 20, 40, 60, 80, 35`, prints the three results, and frees the tree.

Expected output:

```
count: 8
min: 20
max: 80
```

## Exercise 22.8 [stretch]

Write `ex8.s` with a *recursive* `struct node *reverse_rec(struct node *head)`
that contains no loop:

```c
struct node *reverse_rec(struct node *head) {
    if (head == NULL || head->next == NULL)
        return head;
    struct node *rest = reverse_rec(head->next);
    head->next->next = head;     // the node after head now points back at it
    head->next = NULL;
    return rest;
}
```

Trace it on paper for `1 -> 2 -> 3` before you write it. `main` builds
`1 2 3 4 5`, prints it, reverses it, prints it again, and frees it.

Expected output:

```
before: 1 2 3 4 5
reversed: 5 4 3 2 1
```

## Exercise 22.9 [stretch]

Write `ex9.s` with `struct tree *bst_delete(struct tree *t, long key)`, which
removes `key` (if present), frees one node, and returns the new root of the
subtree. There are three cases when you find the node:

1. No left child: return its right child (which may be `NULL`) and free it.
2. No right child: return its left child and free it.
3. Two children: find the smallest key in the right subtree (the "successor"),
   copy that key into this node, then delete the successor key from the right
   subtree: `t->right = bst_delete(t->right, succ_key)`.

`main` builds the tree from `50, 30, 70, 20, 40, 60, 80, 35`, prints it in
order, then deletes 20, 30, 50, and 99 in turn, printing the tree after each.
Finally it frees the tree.

Expected output:

```
start: 20 30 35 40 50 60 70 80
delete 20: 30 35 40 50 60 70 80
delete 30: 35 40 50 60 70 80
delete 50: 35 40 60 70 80
delete 99: 35 40 60 70 80
```

Which case does each deletion exercise? Draw the tree after each step.
