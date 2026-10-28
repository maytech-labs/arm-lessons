# Lesson 31 solutions: design notes

Each project is in its own directory with its own Makefile; `make` here builds
all five (the Makefile in this directory just runs `make` in each one). Test them
all from the lesson directory:

```console
$ make -C solutions
$ ./tests/check.sh all solutions
```

Every solution starts with a header comment saying how to run it and, for the
larger ones, the C it follows. These notes explain the choices that the code
does not. There is more than one good design for each project: if yours passes
the tests and you can explain every register, it is a good solution.

## wc (`wc/wc.s`)

- Three functions: `count_stream` (the `fread` loop and the word state machine),
  `print_counts`, and `main` (flags, files, totals).
- The 64 KiB buffer, `cur[3]` and `total[3]` are in `.bss`, `flags` in `.data`:
  all fixed size, and shared by several functions.
- `count_stream` keeps `lines`, `words`, `bytes` and `inword` in `x21`-`x24`,
  because each `fread` call would destroy temporaries. The inner scanning loop
  makes no calls, so its pointer, end pointer and current byte live in `x9`-`x12`.
- `inword` survives from one chunk to the next, so a word split by the 64 KiB
  boundary is counted once.
- `lines += (ch == '\n')` is `cmp` and `cinc`: no branch.
- The whitespace test `ch == ' ' || (ch >= 9 && ch <= 13)` uses the unsigned
  range trick from lesson 10: `sub w12, w11, #9` then `cmp w12, #4` / `b.ls`
  is true exactly for 9..13.
- `print_counts` tests bit `i` of `flags` with `lsr` by a register and `tbz`.
- The `cannot open` path calls `__errno_location` *immediately* after `fopen`
  fails, before any other call can change `errno`.

## rpn (`rpn/rpn.s`)

- `main` owns the 1024-byte line buffer; `eval_line` owns the 64-entry stack
  (512 bytes) and the `end` pointer for `strtol`. Both are in stack frames, so
  every line really does start with a fresh stack. The frames are bigger than a
  pre-indexed `stp` can reach, so the prologues `sub sp` first.
- The tokenizer writes a `0` byte over the separator after each token, so tokens
  are C strings without copying.
- Every token goes to `strtol` first. If `*end == 0` it was a number. Otherwise
  a one-character token is checked against `+ - * / %`, and a longer one against
  `dup`, `swap`, `drop` with `strcmp`.
- All five arithmetic operators share one pop-two path; the operator character
  stays in `w9` (no calls in between) to choose the instruction. `/` and `%`
  share the zero check and the `sdiv`; `%` adds an `msub`.
- Every error branches to one exit label, so there is exactly one epilogue.

## wordfreq (`wordfreq/wordfreq.s`)

- The table is a heap array of 16-byte `struct entry { char *key; long count; }`,
  made with `calloc` so every empty slot has `key == NULL`. `table`, `cap` and
  `count` are globals in `.data`.
- `fnv1a` builds both 64-bit constants with `movz`/`movk`.
- `find_slot(table, cap, key)` does the probing and is shared by `add_word`
  (to find or insert) and `grow` (to re-insert). It returns the slot holding
  `key` or the first empty slot.
- `grow` moves the existing key pointers into the new table without copying the
  strings, then frees the old array.
- Reading uses `getchar` a byte at a time into a fixed `.bss` word buffer; extra
  letters of absurdly long words are dropped. Upper case is folded with
  `orr w0, w0, #0x20` after a range check. The letter test
  `sub w1, w0, #'a'` / `cmp w1, #25` / `b.hi` is unsigned, so it also rejects EOF
  (-1), which saves a separate check.
- The entries are compacted to the front of the table itself (empty slots are
  skipped), so no second array is needed, then sorted with `qsort` and a
  comparator that returns `-1`/`1` by count, or `strcmp` of the keys.

## life (`life/life.s`)

- Two fixed 200x200 grids in `.bss`, with a row stride of 200 whatever the real
  width: `index = r * 200 + c`. Fixed sizes avoid `malloc` entirely, at the cost
  of 80 KB of zeros, and the stride is a constant.
- Cells are stored as 0 and 1, not as characters, so counting neighbours is just
  adding 8 bytes. `show` converts each row to `'.'`/`'#'` (with `csel`) in a
  line buffer and prints it with `puts`.
- `load` reads the file with `getc`, so it needs no size up front and short
  lines are automatically dead (the grid starts zeroed).
- `step` is a leaf function: it calls nothing, so it uses only scratch
  registers and needs no frame. Wrapped neighbour rows and columns are chosen
  with `csel`, not `%`.
- `main` swaps the `cur` and `next` pointers after each generation.

## bf (`bf/bf.s`)

- The program is read with `getc` into a heap buffer that doubles with
  `realloc` when full, keeping only command characters (tested with `strchr`
  against `"+-<>[].,"`). That filters in the same pass that reads.
- The bracket stack and the `jump` array are both heap arrays of 8-byte
  positions, sized from the program length. The `+ 8` in their sizes keeps
  `malloc(0)` out of the picture for an empty program.
- The tape is `calloc(30000, 1)`, so it starts zeroed. A `.bss` array would
  work just as well.
- The interpreter loop keeps `code`, `len`, `jump`, `tape`, the cell index and
  `pc` in `x19`-`x24`: `.` and `,` call libc in the middle of the loop.
- Dispatch is a `cmp`/`b.eq` chain. A 256-entry jump table would be faster;
  try it as an extra exercise.
- `die(msg)` prints to stderr and calls `exit(1)`, which (unlike returning from
  a function in the middle of `main`) also flushes any buffered output. Every
  fatal error goes through it.
