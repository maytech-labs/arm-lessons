# Lesson 22 solutions

Programming solutions are `exK.s` in this directory. Build and run them with:

```console
$ make
$ ./ex3
```

Below are the answers to the written exercises, and notes on the programs.

## Exercise 22.1

1. Each `push_front` puts the new node in front of the old head:

   | address | value | next |
   |---------|-------|------|
   | `0x1000` | 5 | `0` (NULL) |
   | `0x1020` | 6 | `0x1000` |
   | `0x1040` | 7 | `0x1020` |

   ```
   head -> 0x1040 [7 | 0x1020] -> 0x1020 [6 | 0x1000] -> 0x1000 [5 | NULL]
   ```

2. `head` holds `0x1040`, the node made last.
3. `head->next` is `0x1020`, its `next` is `0x1000`, whose value is **5**.
4. `0x1028` is `0x1020 + NODE_NEXT`: the `next` field of the node holding 6, so
   it holds `0x1000` (as 8 little-endian bytes: `00 10 00 00 00 00 00 00`).
5. `list: 7 6 5`.

## Exercise 22.2

1. It frees the node and *then* reads `next` from it:
   `free(p); p = p->next;`. Reading memory after freeing it is a
   use-after-free.
2. `free` usually changes only a few bytes of the block (often the first 8 or
   16, to link it into its own free list), and nothing else calls `malloc`
   between `free` and the `ldr`. So the old `next` is often still there. It can
   break at any time: a different `malloc` implementation, a debugging
   allocator, or a `MALLOC_PERTURB_` setting (Linux) that fills freed memory
   with junk.
3. Save `next` in a callee-saved register before the call:

   ```asm
   free_list_loop:
       cbz x19, free_list_done
       ldr x20, [x19, #NODE_NEXT]  // read next while p is still ours
       mov x0, x19
       bl free
       mov x19, x20
       b free_list_loop
   ```

   (Remember to save and restore `x20` in the prologue and epilogue.)

## Exercise 22.3

`list_max` must use a **signed** comparison (`gt`, `lt`, ...), because values
are `long`. With unsigned `hi`, -2 (`0xffff...fffe`) would look like the largest
value and the program would print `max: -2`.

## Exercise 22.5

The pointer-to-pointer version never asks "is this the head?". `link` always
points at *the field that points at the current node*: first `head` itself
(on the stack), later some node's `next` field. Rewriting `*link` is the same
instruction either way: `str x9, [x19]`.

After removing a node, `link` stays where it is, because the node that moved up
into `*link` has not been checked yet. That is how `1 1 1` becomes empty.

## Exercise 22.6

1. Every key is larger than all the keys before it, so every node goes to the
   right of the previous one:

   ```
   1
    \
     2
      \
       3
        ...
          \
           7
   ```

   The height is **7**. Searching for 7 compares against every node: **7
   comparisons**. It is a linked list wearing a tree costume.

2. Insert the middle first, then the middles of each half: `4 2 6 1 3 5 7`
   (many other orders work, such as `4 6 2 7 5 3 1`). The tree has height 3:

   ```
         4
       /   \
      2     6
     / \   / \
    1   3 5   7
   ```

3. `bst_print` makes one frame per node on the path it is currently following
   (calls on `NULL` return before building a frame). On the chain that is
   **7 frames**; on the balanced tree, **3 frames**. With *n* sorted keys the
   depth is *n*, which is how a degenerate tree can overflow the stack.

4. Search follows a *single* path and never needs to come back, so a loop
   with one pointer does the job, with no stack use at all. Printing must visit
   *both* subtrees of every node, so it has to remember where to come back to;
   recursion keeps that memory in stack frames for free. A loop version would
   need its own explicit stack of nodes.

## Exercise 22.8

Trace on `1 -> 2 -> 3`:

- `reverse_rec(1)` calls `reverse_rec(2)`, which calls `reverse_rec(3)`.
- `reverse_rec(3)`: `3->next` is NULL, so it returns 3.
- Back in `reverse_rec(2)`: `rest = 3`. `2->next` is 3, so `3->next = 2`, then
  `2->next = NULL`. List from 3: `3 -> 2`. Returns 3.
- Back in `reverse_rec(1)`: `rest = 3`. `1->next` is still 2, so `2->next = 1`,
  then `1->next = NULL`. List from 3: `3 -> 2 -> 1`. Returns 3.

The trick is that `head->next` still points at the old second node, which is
now the *last* node of the reversed rest.

## Exercise 22.9

- `delete 20`: 20 is a leaf (no children), handled by case 1: the parent's
  left pointer becomes NULL.
- `delete 30`: 20 is gone, so 30 has only a right child (40). Case 1: 50's left
  becomes 40.
- `delete 50`: the root has two children. The successor is the smallest key on
  the right, 60. 60 is copied into the root, then deleted from the right
  subtree, where it is a leaf.
- `delete 99`: not found; the recursion reaches `NULL` and returns it, and
  nothing changes.

```
start          after 20       after 30       after 50
     50             50             50             60
    /  \           /  \           /  \           /  \
  30    70       30    70       40    70       40    70
 / \   / \         \   / \     /     / \     /       \
20 40 60 80        40 60 80   35    60 80   35        80
   /              /
  35             35
```
