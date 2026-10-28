# Lesson 31 exercises: the capstone projects

Five projects, each a complete command-line tool. They are bigger than any
exercise so far: expect each one to take an evening or several.

How to work:

- Work in `work/` inside this lesson (it is git-ignored), one directory per
  project, each with a one-line Makefile. For example:

  ```console
  $ mkdir -p work/wc && cd work/wc
  $ printf 'include ../../../../mk/linux.mk\n' > Makefile
  ```

- Write the program in C first and test it. Then translate it, one function and
  one milestone at a time (see "A method for big programs" in the README).
- Test with `check.sh` from the lesson directory:

  ```console
  $ ./tests/check.sh wc work/wc/wc
  ```

  The test inputs and the expected outputs are the files in `tests/PROJECT/`.
  Look at them: `NAME.out` is the expected stdout of test `NAME`, `NAME.err` its
  expected stderr, and the `cases` file lists the arguments, input and exit
  status of each test.
- Solutions are in `solutions/PROJECT/PROJECT.s`. Try first: you learn far more
  from a bug you find yourself than from a solution you read. Notes on the
  design of each solution are in [solutions/README.md](solutions/README.md).

---

## Exercise 31.1: wc [core]

File: `work/wc/wc.s`, built as `work/wc/wc`.

### Requirements

`wc [-l] [-w] [-c] [FILE...]` counts the lines, words and bytes of each file.

- `-l` lines, `-w` words, `-c` bytes. Flags may be given separately (`-l -w`) or
  combined (`-lw`), and must come before the file names. No flags at all means
  all three.
- The counts are always printed in the order lines, words, bytes, whatever order
  the flags came in. Each selected count is printed with `printf("%8ld", n)`.
  After the counts, if the input was a file, print `" "` and the file name. Then
  `"\n"`.
- With no file names, read stdin and print no name.
- With more than one file, print one more line at the end with the totals and
  the name `total`.
- A line is a `'\n'` byte. A word is a maximal run of non-whitespace bytes, where
  whitespace is space, `\t`, `\n`, `\v`, `\f`, `\r`. Bytes is every byte.
- Unknown flag, e.g. `-x`: print `wc: unknown option -x` and then
  `usage: wc [-l] [-w] [-c] [file...]` on stderr, and exit with status 2.
- A file that cannot be opened: print `wc: NAME: REASON` on stderr, where
  `REASON` is `strerror(errno)`, carry on with the next file, and exit with status
  1 at the end. The total line (if any) counts only the files that opened.
- Otherwise exit 0.
- Read with `fread` in 64 KiB chunks.

### Suggested design

- Globals in `.bss`: the 64 KiB buffer, `long cur[3]`, `long total[3]`; in
  `.data`: `int flags` (bit 0 = `-l`, bit 1 = `-w`, bit 2 = `-c`).
- `void count_stream(FILE *f, long *c)`: the `fread` loop and the word state
  machine. The scanning loop calls nothing, so it can use temporaries.
- `void print_counts(long *c, const char *name)`: loops `i = 0..2`, prints `c[i]`
  if bit `i` of `flags` is set; `name` may be `NULL`.
- `main`: parse flags, then either `count_stream(stdin)` or a loop over files.

### Milestones

1. Count bytes from stdin and print them with `%8ld`.
2. Add lines.
3. Add words. Test with several spaces and tabs in a row, and with input that
   does not end in a newline.
4. Read a file named in `argv[1]` instead of stdin when there is one.
5. Several files, and the `total` line.
6. Flags, then error handling.

### Tests

```console
$ printf 'hello world\nfoo\n' | ./wc
       2       3      16
$ ./wc -lw poem.txt
       5      13 poem.txt
$ ./wc -c -l hello.txt
       2      16 hello.txt
$ ./wc hello.txt missing.txt poem.txt; echo $?
       2       3      16 hello.txt
wc: missing.txt: No such file or directory
       5      13      65 poem.txt
       7      16      81 total
1
$ ./wc -x hello.txt; echo $?
wc: unknown option -x
usage: wc [-l] [-w] [-c] [file...]
2
```

(The files are in `tests/wc/`. The error line goes to stderr, so in a terminal it
may appear in a slightly different place.) All of them:
`./tests/check.sh wc work/wc/wc`.

---

## Exercise 31.2: rpn [core]

File: `work/rpn/rpn.s`, built as `work/rpn/rpn`.

### Requirements

`rpn` is a reverse Polish notation calculator. It reads stdin line by line and
evaluates each line on its own.

- Read lines with `fgets` into a 1024-byte buffer.
- Each line starts with a fresh, empty stack that holds up to 64 signed 64-bit
  values (`long`).
- Tokens are separated by spaces, tabs and the newline.
- A token is a number if `strtol(tok, &end, 10)` consumes all of it. So `-5` and
  `+7` are numbers, but `-` is subtraction and `12abc` is an unknown token.
  Push the number.
- Operators `+ - * / %` pop `b` (the top) and then `a`, and push `a OP b`, with
  C's truncating semantics (`-7 / 2` is `-3`, `-7 % 2` is `-1`). Dividing or
  taking the remainder by zero is an error.
- `dup` pushes a copy of the top value, `swap` swaps the top two, `drop` throws
  the top away.
- At the end of a line:
  - no tokens at all (an empty or blank line): print nothing;
  - exactly one value on the stack: print it with `printf("%ld\n", v)`;
  - otherwise: `error: N values left on stack`.
- Errors are printed to **stdout** (to keep the tests simple), followed by
  `"\n"`; the rest of that line is skipped and the next line starts fresh:
  - `error: stack underflow` (not enough values for an operator),
  - `error: stack overflow` (a push onto a full stack),
  - `error: division by zero`,
  - `error: unknown token 'TOK'`.
- Exit 0 at end of input.

### Suggested design

- `main`: a 1024-byte buffer in its frame, `fgets` loop, `eval_line(line)`.
- `void eval_line(char *p)`: the stack array (512 bytes) and the `end` pointer
  for `strtol` both live in its frame. Split tokens in place by writing a `0`
  byte after each one.
- Single-character operators are easy to test with `ldrb`; the word commands
  with `strcmp`.
- `a % b` is `a - (a / b) * b`: `sdiv` then `msub`.

### Milestones

1. Print each token of each line on its own line (tokenizer only).
2. Push numbers; at the end of the line print the top.
3. `+ - *`. Then `/ %` with the zero check.
4. `dup swap drop`, and all the error messages.

### Tests

```console
$ printf '3 4 + 2 *\n5 1 2 + 4 * + 3 -\n1 0 /\n1 +\n1 2\n\n2 dup *\n1 2 swap -\n7 -2 %%\n' | ./rpn
14
14
error: division by zero
error: stack underflow
error: 2 values left on stack
4
1
1
```

(`%%` is how you write one `%` in a `printf` format, including the shell's
`printf`.) The full test input is `tests/rpn/input.txt`, with its expected output
in `tests/rpn/all-lines.out`. All of them: `./tests/check.sh rpn work/rpn/rpn`.

---

## Exercise 31.3: wordfreq [stretch]

File: `work/wordfreq/wordfreq.s`, built as `work/wordfreq/wordfreq`.

### Requirements

`wordfreq [N]` prints the `N` most common words on stdin (default 10).

- A word is a maximal run of ASCII letters `A`-`Z`, `a`-`z`, converted to lower
  case. Everything else separates words: `don't` is the two words `don` and `t`.
- Count the words with your own hash table:
  - open addressing with linear probing (on a collision, try the next slot,
    wrapping round at the end);
  - FNV-1a 64-bit hash: start with `h = 0xcbf29ce484222325`; for each byte,
    `h ^= byte; h *= 0x100000001b3`;
  - the capacity is a power of two, starting at 16; the slot is
    `h & (capacity - 1)`;
  - grow (double the capacity and re-insert everything) when
    `count * 10 >= capacity * 7`, where `count` is the number of distinct words;
  - keys are copies made with `strdup`.
- Then copy the entries into an array and sort it with `qsort`: by count,
  highest first; equal counts by word, in `strcmp` order.
- Print the first `N` entries with `printf("%7ld %s\n", count, word)`. If there
  are fewer than `N` distinct words, print them all. No words: print nothing.
- Exit 0.

### Suggested design

- `struct entry { char *key; long count; }`: 16 bytes. The table is
  `calloc(capacity, 16)`, so an empty slot has `key == NULL`.
- Globals: `table`, `capacity`, `count`.
- `uint64_t fnv1a(const char *s)`.
- `void add_word(const char *w)`: grow first if needed, then probe for `w`; if
  found, `count++`; if an empty slot is reached, `strdup` it in.
- `void grow(void)`: allocate the bigger table, re-insert every key (no
  `strdup` this time: move the pointers), `free` the old one.
- Read the words with `getchar` a byte at a time into a word buffer (stop adding
  letters at, say, 255; a real program would grow it).
- `int compare(const void *a, const void *b)`: the `qsort` comparator.
  `qsort` calls it, so it is an ordinary function that follows the calling
  convention.

### Milestones

1. Print every word, lower-cased, one per line.
2. A fixed-size table with no growing (make it 4096 slots) and print the whole
   table in slot order.
3. `qsort` and the top `N`.
4. Start at 16 and grow. Test with an input that has many distinct words.

### Tests

The input is the start of *A Tale of Two Cities* plus a line of awkward cases,
in `tests/wordfreq/input.txt`.

```console
$ ./wordfreq 3 < input.txt
     18 the
     12 of
     11 was
$ ./wordfreq < input.txt
     18 the
     12 of
     11 was
     10 it
      4 we
      3 t
      2 age
      2 all
      2 before
      2 direct
$ printf 'b a c b a b\n' | ./wordfreq 5
      3 b
      2 a
      1 c
```

All of them: `./tests/check.sh wordfreq work/wordfreq/wordfreq`.

---

## Exercise 31.4: life [stretch]

File: `work/life/life.s`, built as `work/life/life`.

### Requirements

`life [-a] FILE GENERATIONS` runs Conway's Game of Life.

- `FILE` holds the starting grid: one line per row, `'.'` for a dead cell and
  `'#'` for a live one. The width is the longest line; shorter lines are padded
  with dead cells. At most 200 rows and 200 columns.
- `GENERATIONS` is a number `G` (use `atoi`).
- The edges wrap round: the grid is a torus. The neighbour above row 0 is the
  last row; the neighbour left of column 0 is the last column.
- Each generation, every cell counts its 8 neighbours. A live cell with 2 or 3
  live neighbours stays alive; a dead cell with exactly 3 becomes alive; every
  other cell is dead in the next generation. All cells change at once.
- Without `-a`: for `g = 0, 1, ..., G`, print `Generation g:` and `"\n"`, then
  each row of the grid followed by `"\n"`, then an empty line `"\n"`.
  Generation 0 is the input.
- With `-a` (animate): before each generation print `"\033[H\033[2J"` (move the
  cursor home and clear the screen), then the same header and rows, with no
  empty line after them, then `usleep(100000)` (a tenth of a second).
- Wrong arguments: `usage: life [-a] FILE GENERATIONS` on stderr, exit 2.
- A file that cannot be opened: `life: NAME: REASON` on stderr (`strerror`),
  exit 1.
- Otherwise exit 0.

### Suggested design

- Read the file with the `slurp` example's method. A first pass over the
  buffer finds the number of rows and the longest line.
- Two grids of `rows * cols` bytes from `malloc`, holding `'.'` and `'#'`. Fill
  the first from the file (`'.'` where a line is short).
- `int neighbours(char *grid, int r, int c)`: 8 loads, with wrapped row and
  column numbers computed with `csel`.
- `void step(char *cur, char *next)`: one generation.
- `void print_grid(char *grid)`: each row is `fwrite(grid + r * cols, 1, cols,
  stdout)` and then `putchar('\n')`.
- In `main`, swap the `cur` and `next` pointers after each step.

### Milestones

1. Read the file and print it back as generation 0 (check the padding with
   `tests/life/ragged.txt`).
2. `neighbours`, tested by printing the neighbour count of every cell instead of
   the cell.
3. `step` and the generation loop. The blinker must blink.
4. `-a`, then the error handling.

### Tests

`tests/life/blinker.txt` is a 5x5 grid with a vertical line of three cells:

```console
$ ./life blinker.txt 2
Generation 0:
.....
..#..
..#..
..#..
.....

Generation 1:
.....
.....
.###.
.....
.....

Generation 2:
.....
..#..
..#..
..#..
.....

```

`tests/life/glider.txt` is an 8x8 grid with a glider in the top-left corner.
After 4 generations it has moved one cell down and one right:

```console
$ ./life glider.txt 4 | tail -n 10
Generation 4:
........
..#.....
...#....
.###....
........
........
........
........

```

After 32 generations it has crossed the whole torus and is back where it
started (test `glider-wrap`). Try `./life -a glider.txt 100` in a terminal to
watch it. All of them: `./tests/check.sh life work/life/life`.

---

## Exercise 31.5: bf [stretch]

File: `work/bf/bf.s`, built as `work/bf/bf`.

### Requirements

`bf FILE` runs the Brainfuck program in `FILE` (the command table is in the
README).

- Read the whole file. Keep only the eight command characters `> < + - . , [ ]`
  and throw everything else away (it is comments).
- Before running, match the brackets with a stack and store, for every `[` and
  `]`, the position of its partner in a jump array. A `]` with no `[` before it:
  `bf: unmatched ]` on stderr, exit 1. A `[` that is never closed:
  `bf: unmatched [` on stderr, exit 1.
- The tape is 30000 unsigned bytes, all 0 at the start; the pointer starts at
  cell 0. `+` and `-` wrap round (255 + 1 is 0, 0 - 1 is 255).
- If `>` or `<` would move the pointer outside 0..29999: `bf: tape pointer out
  of range` on stderr, exit 1.
- `.` writes the current cell with `putchar`. `,` reads a byte with `getchar`;
  at end of input it stores 0.
- When the program finishes, exit 0.
- Wrong arguments: `usage: bf FILE` on stderr, exit 2. A file that cannot be
  opened: `bf: NAME: REASON` on stderr (`strerror`), exit 1.

### Suggested design

- The tape in `.bss` (30000 bytes); the program and the jump array on the heap
  (the program is at most as long as the file, and `jump` needs one `int` per
  command).
- Pass 1: filter the file buffer in place into the program.
- Pass 2: bracket matching with an array used as a stack.
- Pass 3: the interpreter loop. Keep `pc`, the tape base and `ptr` in
  callee-saved registers, because `.` and `,` call libc.
- Dispatch with a `cmp`/`b.eq` chain first. A 256-entry jump table indexed by the
  command byte (lesson 24) is a good improvement once it works.

### Milestones

1. Read and filter: print the filtered program.
2. Run programs without loops: `+ - < > .`. A file holding 53 `+` and one `.`
   prints `5`, because 53 is the character code of `'5'`.
3. Bracket matching and loops: `tests/bf/hello.bf` must print `Hello World!`.
4. `,` and the error checks.

### Tests

```console
$ ./bf hello.bf
Hello World!
$ printf 'abc' | ./bf rev.bf
cba$ ./bf cat.bf < poem.txt
The quick brown fox
jumps over
the lazy dog.

It was not amused.
$ ./bf unmatched.bf; echo $?
bf: unmatched [
1
$ ./bf range.bf; echo $?
bf: tape pointer out of range
1
```

(`rev.bf` prints `cba` with no newline, so the next prompt follows straight
on.) All of them: `./tests/check.sh bf work/bf/bf`.

---

When all five pass, run them all against the tests in one go:

```console
$ ./tests/check.sh all work
```
