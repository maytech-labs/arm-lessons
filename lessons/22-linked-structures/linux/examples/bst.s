// bst.s - a binary search tree: insert, search, in-order print, height, free (lesson 22)
//
// Build: make bst
// Run:   ./bst
// Expected output:
//   in order: 20 30 35 40 50 60 70 80
//   height: 4
//   search 60: found
//   search 65: not found
//
// Keys are inserted in this order: 50 30 70 20 40 60 80 35, giving
//
//              50
//            /    \
//          30      70
//         /  \    /  \
//       20   40  60   80
//           /
//          35

// struct tree { long key; struct tree *left; struct tree *right; };
    .equ TREE_KEY,   0
    .equ TREE_LEFT,  8
    .equ TREE_RIGHT, 16
    .equ TREE_SIZE,  24

    .equ NKEYS, 8               // how many entries the keys table has

    .text
    .global main
    .p2align 2

// struct tree *bst_insert(struct tree *t, long key)
//     if (t == NULL) { make a new leaf and return it }
//     if (key < t->key)      t->left  = bst_insert(t->left, key);
//     else if (key > t->key) t->right = bst_insert(t->right, key);
//     return t;              (equal keys are ignored)
bst_insert:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // t
    mov x20, x1                 // key
    cbnz x19, bst_insert_descend
    mov x0, #TREE_SIZE          // t == NULL: new leaf
    bl malloc
    cbz x0, out_of_memory
    str x20, [x0, #TREE_KEY]
    str xzr, [x0, #TREE_LEFT]
    str xzr, [x0, #TREE_RIGHT]
    b bst_insert_done           // return the new leaf
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
bst_insert_right:
    ldr x0, [x19, #TREE_RIGHT]
    mov x1, x20
    bl bst_insert
    str x0, [x19, #TREE_RIGHT]  // t->right = bst_insert(t->right, key)
    mov x0, x19
bst_insert_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// struct tree *bst_search(struct tree *t, long key)
// Iterative: one path from the root down, no stack needed. Leaf function.
//     while (t != NULL && t->key != key)
//         t = key < t->key ? t->left : t->right;
//     return t;
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

// void bst_print(struct tree *t)       in-order: left, node, right
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

// long bst_height(struct tree *t)
//     if (t == NULL) return 0;
//     long l = bst_height(t->left), r = bst_height(t->right);
//     return 1 + (l > r ? l : r);
bst_height:
    cbz x0, bst_height_done     // NULL: height 0 (x0 is already 0)
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #TREE_LEFT]
    bl bst_height
    mov x20, x0                 // l, kept in a callee-saved register
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_height               // x0 = r
    cmp x20, x0
    csel x0, x20, x0, gt        // max(l, r)
    add x0, x0, #1
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
bst_height_done:
    ret

// void bst_free(struct tree *t)        post-order: children before parent
bst_free:
    cbz x0, bst_free_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #TREE_LEFT]
    bl bst_free
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_free
    mov x0, x19
    bl free                     // last: after this, t->left is gone too
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
bst_free_done:
    ret

out_of_memory:
    adrp x0, msg_oom
    add x0, x0, :lo12:msg_oom
    bl puts
    mov w0, #1
    bl exit

// void report_search(struct tree *t, long key)
report_search:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x20, x1                 // key
    bl bst_search
    adrp x9, fmt_found
    add x9, x9, :lo12:fmt_found
    adrp x10, fmt_missing
    add x10, x10, :lo12:fmt_missing
    cmp x0, #0
    csel x0, x9, x10, ne
    mov x1, x20
    bl printf                   // printf(found ? "...found" : "...not found", key)
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

main:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]     // x19 = root, x20 = i
    str x21, [sp, #32]          // x21 = &keys[0]

    mov x19, #0                 // root = NULL
    adrp x21, keys
    add x21, x21, :lo12:keys
    mov x20, #0
main_insert:                    // for (i = 0; i < NKEYS; i++)
    mov x0, x19
    ldr x1, [x21, x20, lsl #3]
    bl bst_insert
    mov x19, x0                 //     root = bst_insert(root, keys[i])
    add x20, x20, #1
    cmp x20, #NKEYS
    b.lo main_insert

    adrp x0, msg_inorder
    add x0, x0, :lo12:msg_inorder
    bl printf
    mov x0, x19
    bl bst_print
    mov w0, #10
    bl putchar

    mov x0, x19
    bl bst_height
    mov x1, x0
    adrp x0, fmt_height
    add x0, x0, :lo12:fmt_height
    bl printf

    mov x0, x19
    mov x1, #60
    bl report_search
    mov x0, x19
    mov x1, #65
    bl report_search

    mov x0, x19
    bl bst_free
    mov w0, #0
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

    .section .rodata
    .p2align 3
keys:        .quad 50, 30, 70, 20, 40, 60, 80, 35
fmt_item:    .asciz " %ld"
msg_inorder: .asciz "in order:"
fmt_height:  .asciz "height: %ld\n"
fmt_found:   .asciz "search %ld: found\n"
fmt_missing: .asciz "search %ld: not found\n"
msg_oom:     .asciz "out of memory"
