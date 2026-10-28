# Lesson 25: I/O and arguments

Until now your programs have done the same thing every time you ran them. Real
programs take arguments (`ls -l /tmp`), read the environment (`$HOME`), read and
write files, report errors properly, and finish with an exit status that tells
the shell whether they worked. This lesson covers all of that, and ends with you
writing small clones of `cat`, `wc`, and `head`.

## Goals

After this lesson you can:

- Read `argc`, `argv`, and `envp` in `main`, and walk `argv` both by count and
  until its `NULL` terminator.
- Say where `argc` and `argv` are on the stack when a program starts at `_start`.
- Look up an environment variable with `getenv`.
- Use the standard streams `stdin`, `stdout`, `stderr` from assembly, through the GOT.
- Open, write, read, and close files with `fopen`, `fprintf`, `fgets`,
  `fgetc`/`fputc`, `fputs`, `fclose`.
- Detect failures, read `errno`, and print a message with `perror`.
- Use the unbuffered calls `open`/`read`/`write`/`close` and raw system calls,
  and explain how they differ from stdio's buffered I/O.
- Follow the exit status conventions: 0 for success, non-zero for failure.

## Before you start

You need:

- [Lesson 13](../13-the-stack/) and [lesson 14](../14-functions/): stack frames,
  keeping locals and buffers on the stack.
- [Lesson 15](../15-calling-convention/): which registers survive a call.
- [Lesson 16](../16-calling-c/): calling libc from `main`.
- [Lesson 17](../17-strings/): C strings, `strlen`, `strcmp`, `atoi`.
- [Lesson 19](../19-structs-and-unions/): structs via `.equ` offsets (one exercise).
- [Lesson 20](../20-symbols-and-sections/): globals and `extern` symbols.

All examples are in [`examples/`](examples/). Build them once:

```console
$ cd lessons/25-io-and-args/examples
$ make
```

## 1. What `main` really receives

In C, `main` can take two (or three) parameters:

```c
int main(int argc, char **argv)
```

- `argc` ("argument count") is an `int`: how many words were on the command line,
  **including the program name**.
- `argv` ("argument vector") is a pointer to an array of `char *`. Each element
  points at one argument, as a normal NUL-terminated C string.

If you type `./args hello "two words" 3`, the shell splits the line into words
(quotes keep `two words` together), and your program gets:

```
argc = 4

argv ──> [0] ──> "./args\0"
         [1] ──> "hello\0"
         [2] ──> "two words\0"
         [3] ──> "3\0"
         [4]  =  NULL
```

Two facts to remember:

1. `argv[0]` is the program name, exactly as typed (`./args`, not `args`).
2. There is always one extra element, `argv[argc]`, and it is `NULL`. So you can
   stop either when `i == argc` or when you load a zero pointer.

`main` is just a function, so the calling convention from lesson 15 applies:
`argc` arrives in `w0` (it is an `int`) and `argv` in `x1`. Each `argv[i]` is an
8-byte pointer, so element `i` is at `argv + i * 8`.

The C program:

```c
int main(int argc, char **argv) {
    printf("argc = %d\n", argc);
    for (int i = 0; i < argc; i++)
        printf("argv[%d] = %s\n", i, argv[i]);
    return 0;
}
```

The heart of [`examples/args.s`](examples/args.s):

```asm
    mov w19, w0                 // w19 = argc (an int, 32 bits)
    mov x20, x1                 // x20 = argv (a pointer to an array of pointers)
    ...
    mov x21, #0                 // i = 0
main_loop:
    cmp x21, x19                // i < argc ?  (argc is never negative)
    b.ge main_done
    adrp x0, fmt_argv
    add x0, x0, :lo12:fmt_argv
    mov w1, w21                 // i
    ldr x2, [x20, x21, lsl #3]  // argv[i]: 8-byte pointers, so scale by 8
    bl printf
    add x21, x21, #1
    b main_loop
```

`argc` and `argv` live in callee-saved registers (`x19`, `x20`) because `printf`
is free to destroy `x0`-`x18`. `mov w19, w0` also zeroes the top half of `x19`,
so comparing the whole `x21` with `x19` is safe.

Predict the output of `./args hello "two words" 3`, then check:

```console
$ ./args hello "two words" 3
argc = 4
argv[0] = ./args
argv[1] = hello
argv[2] = two words
argv[3] = 3
```

Try `./args` alone (what is `argc`?), and `./args '*'` versus `./args *`.
The shell expands `*` into file names before your program ever runs: your
program only sees the finished words.

## 2. Before `main`: the stack at `_start`

Who calls `main` with those arguments? On Linux, the kernel starts your program
at `_start` (lesson 04). It does not put anything in `x0` or `x1`. Instead it
lays everything out on the stack:

```
sp + 0     argc                (8 bytes)
sp + 8     argv[0]             pointer
sp + 16    argv[1]             pointer
 ...
           NULL                (argv[argc])
           envp[0], envp[1], ...
           NULL                (end of envp)
           ... the strings themselves, higher up
```

When you link with libc, the C library's own `_start` reads this, sets up
`stdio` and friends, and then calls `main(argc, argv, envp)`. A freestanding
program (no libc) has to read it itself.
[`examples/start_args.s`](examples/start_args.s) does exactly that, with only
raw system calls, like lessons 04-15:

```asm
_start:
    ldr x19, [sp]               // x19 = argc
    add x20, sp, #8             // x20 = argv = address of argv[0]
```

Note the difference: `argc` is a *value* on the stack, so we load it. `argv` is
the *address* where the pointer array starts, so we compute `sp + 8` with `add`,
not a load. The rest of the program is a loop of hand-written `strlen` and
`write`, and the exit status is `argc`.

```console
$ ./start_args red green; echo $?
./start_args
red
green
3
```

You will rarely write `_start` yourself again; this is just so you know `argc`
and `argv` are not magic.

## 3. The environment

Every process also gets a list of `NAME=value` strings, the *environment*
(`HOME=/root`, `PATH=...`). You see it with the `env` command.

### `envp`, the third argument

`main` may take a third parameter, `char **envp`, which is laid out exactly like
`argv` and ends with `NULL`. There is no count, so you must walk it until the
`NULL`:

```c
int main(int argc, char **argv, char **envp) {
    int n = 0;
    for (char **p = envp; *p != NULL; p++) { puts(*p); n++; }
    printf("%d variables\n", n);
    return 0;
}
```

It arrives in `x2`. From [`examples/envp.s`](examples/envp.s):

```asm
    mov x19, x2                 // x19 = p = envp (third argument)
    mov x20, #0                 // n = 0
main_loop:
    ldr x0, [x19]               // x0 = *p
    cbz x0, main_done           // the array ends with a NULL pointer
    bl puts
    add x20, x20, #1
    add x19, x19, #8            // p++ (next pointer)
    b main_loop
```

`p++` on a `char **` adds 8, the size of one pointer (lesson 12). Your real
environment is long and different on every machine, so run it with `env -i`,
which starts the program with an empty environment plus the variables you list:

```console
$ env -i A=1 B=two ./envp
A=1
B=two
2 variables
```

### `getenv`

Usually you want one variable by name. `getenv(name)` searches the environment
and returns a pointer to the part after the `=`, or `NULL` if it is not set.
**Always check for `NULL`**: passing `NULL` to `printf("%s")` or `strlen`
crashes or prints garbage.

```c
char *v = getenv("GREETING");
if (v == NULL) puts("GREETING is not set");
else printf("GREETING is %s\n", v);
```

In [`examples/getenv.s`](examples/getenv.s) that is a call and a `cbz`:

```asm
    adrp x0, name
    add x0, x0, :lo12:name
    bl getenv                   // x0 = pointer to the value, or NULL
    cbz x0, main_unset
```

```console
$ GREETING=hello ./getenv
GREETING is hello
$ env -u GREETING ./getenv
GREETING is not set
```

(`NAME=value command` sets a variable for one command only. `env -u NAME`
removes one.) Never write through the pointer `getenv` returns: it points into
the environment itself.

## 4. Exit status conventions

`return n` from `main` (or `exit(n)`) hands the shell an exit status, which you
read with `echo $?`. Only the low 8 bits survive, so it is 0-255. The
conventions every Unix tool follows:

| Status | Meaning | Example |
|--------|---------|---------|
| 0 | success (`EXIT_SUCCESS`) | `cat` copied every file |
| 1 | failure (`EXIT_FAILURE`) | a file could not be opened |
| 2 | wrong usage | `head -n` with no number (by tradition, as `grep` and `diff` do) |

Some tools give other values a meaning: `grep` returns 0 if it found a match and
1 if it did not. The shell's `&&` and `||` run the next command only on success
or failure, so a correct status makes your program composable:

```console
$ ./cat nope.txt && echo worked || echo failed
nope.txt: No such file or directory
failed
```

## 5. The standard streams

Every process starts with three open streams:

| C name | File descriptor | Used for | Default |
|--------|-----------------|----------|---------|
| `stdin` | 0 | input | the keyboard (or a pipe, or `< file`) |
| `stdout` | 1 | normal output | the terminal (or `> file`, or a pipe) |
| `stderr` | 2 | error messages | the terminal, even when stdout is redirected |

Error messages go to `stderr` so that `prog > out.txt` captures the real output
and still shows you the errors.

### Finding `stdout` from assembly

`printf` and `puts` write to `stdout` implicitly. Functions like `fputs` take
the stream as an argument:

```c
fputs("to stdout\n", stdout);
fputs("to stderr\n", stderr);
```

In C, `stdout` is a global variable declared `extern FILE *stdout;`. It lives
inside the C library (a shared library), not in your program. As in lesson 20,
the address of a symbol in another module is not known until the program is
loaded, so the linker gives you a slot in the **GOT** (global offset table) that
the loader fills in with the real address. You load the address from the GOT,
then load the variable's value:

```asm
    adrp x8, :got:stdout            // page of the GOT slot for stdout
    ldr x8, [x8, :got_lo12:stdout]  // x8 = &stdout   (from the GOT)
    ldr x1, [x8]                    // x1 = stdout    (the FILE *)
```

Three steps, two loads. Compare with your own data, where `adrp`/`add` gives the
address directly. Forget the last `ldr` and you pass `&stdout` (a `FILE **`)
where a `FILE *` is expected: a crash.

[`examples/streams.s`](examples/streams.s) prints one line to each stream and
returns 3. Predict what you see in each case:

```console
$ ./streams; echo $?
to stdout
to stderr
3
$ ./streams 2>/dev/null
to stdout
$ ./streams >/dev/null
to stderr
```

`2>/dev/null` throws away stream 2, `>/dev/null` throws away stream 1. Now try
`./streams 2>&1 | cat`. The lines come out in the *other* order. Section 8
explains why.

## 6. Files with stdio

`<stdio.h>` gives you `FILE *` handles. You never look inside a `FILE`; it is
an opaque struct owned by the library. You only pass the pointer around.

| Call | Does | Returns |
|------|------|---------|
| `fopen(path, mode)` | opens a file. Mode `"r"` read, `"w"` write (create or empty it), `"a"` append | `FILE *`, or `NULL` on failure |
| `fprintf(f, fmt, ...)` | `printf` to a file | number of chars written |
| `fputs(s, f)` | writes a string (no newline added, unlike `puts`) | non-negative, or `EOF` |
| `fgets(buf, size, f)` | reads one line (up to `size - 1` chars), keeps the `'\n'`, adds `'\0'` | `buf`, or `NULL` at end of file or on error |
| `fgetc(f)` / `fputc(c, f)` | one byte in / out | the byte as an `int`, or `EOF` |
| `fclose(f)` | flushes and closes | 0, or `EOF` |

The C program:

```c
FILE *f = fopen("out.txt", "w");
if (f == NULL) { perror("out.txt"); return 1; }
for (int i = 1; i <= 3; i++)
    fprintf(f, "line %d\n", i);
fclose(f);

char buf[128];
f = fopen("out.txt", "r");
if (f == NULL) { perror("out.txt"); return 1; }
while (fgets(buf, sizeof buf, f) != NULL)
    printf("read: %s", buf);      // buf already ends in '\n'
fclose(f);
```

[`examples/stdio_files.s`](examples/stdio_files.s) puts the 128-byte buffer in
the stack frame (lesson 13), above the saved registers:

```asm
    // frame: 16 (fp, lr) + 16 (x19, x20) + 128 (buf) = 160
    stp x29, x30, [sp, #-160]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    // buf is at sp + 32 .. sp + 159
```

The `FILE *` goes in `x19` because it must survive many calls. `fprintf`'s
arguments are the stream in `x0`, the format in `x1`, then the values in `x2`,
`x3`, ...:

```asm
    mov x0, x19                 // fprintf(f, "line %d\n", i)
    adrp x1, fmt_line
    add x1, x1, :lo12:fmt_line
    mov w2, w20
    bl fprintf
```

and the read loop stops when `fgets` returns `NULL`:

```asm
main_read_loop:
    add x0, sp, #32             // fgets(buf, BUFSIZE, f)
    mov w1, #BUFSIZE
    mov x2, x19
    bl fgets                    // returns buf, or NULL at end of file
    cbz x0, main_read_done
```

```console
$ ./stdio_files
read: line 1
read: line 2
read: line 3
$ cat out.txt
line 1
line 2
line 3
```

Why must the file be closed before reopening it to read? What would you read if
you skipped the first `fclose`? (Think about it, then read section 8.)

`make clean` deletes `out.txt` as well as the programs.

## 7. When things fail: `errno` and `perror`

Calls that can fail tell you *that* they failed through their return value
(`NULL`, `-1`, `EOF`). They tell you *why* through `errno`, an `int` the library
sets to an error code: 2 is `ENOENT` ("No such file or directory"), 13 is
`EACCES` ("Permission denied"), and so on. `errno` is only meaningful right
after a call has reported failure; successful calls may leave anything in it.

`perror(s)` prints `s`, a colon, and the message for the current `errno`, to
`stderr`. That is what `cat` does when it says `nope.txt: No such file or directory`.

```c
FILE *f = fopen("no-such-file.txt", "r");
if (f == NULL) {
    int e = errno;               // save it before calling anything else
    perror("no-such-file.txt");
    printf("errno = %d\n", e);
    return 1;
}
```

In assembly there is a catch: `errno` is **not** an ordinary global variable.
Every thread (lesson 28) needs its own copy, so in glibc the name `errno` is a
macro for `(*__errno_location())`, a function that returns the address of the
current thread's `errno`. From [`examples/errno.s`](examples/errno.s):

```asm
    bl fopen                    // x0 = FILE *, or NULL on failure
    cbnz x0, main_opened
    bl __errno_location         // x0 = &errno
    ldr w19, [x0]               // w19 = errno (an int)
```

We copy it into `w19` immediately, because any later call (even `perror`) may
change it.

```console
$ ./errno 2>&1; echo $?
no-such-file.txt: No such file or directory
errno = 2
1
```

## 8. Underneath stdio: file descriptors and system calls

stdio is built on top of a smaller interface: **file descriptors**. A file
descriptor (fd) is a small `int` the kernel gives you when you open a file: 0,
1, 2 are already taken by stdin, stdout, stderr, so your first file is usually
3. You have used `write(1, ...)` since lesson 05. The full set:

| C call (`<fcntl.h>`, `<unistd.h>`) | Linux syscall | Returns |
|-------------------------------------|---------------|---------|
| `open(path, flags, mode)` | `openat` = 56, with `AT_FDCWD` (-100) as the first argument | new fd |
| `read(fd, buf, n)` | 63 | bytes read; 0 at end of file |
| `write(fd, buf, n)` | 64 | bytes written |
| `close(fd)` | 57 | 0 |

AArch64 Linux has no plain `open` system call, only `openat(dirfd, path, flags,
mode)`. Passing `AT_FDCWD` means "relative to the current directory", which is
what `open` does.

There are two ways to make these calls from a `main` program:

- **The libc wrappers** `open`, `read`, `write`, `close`: ordinary function
  calls with `bl`. On failure they return `-1` and set `errno`.
- **The raw system call** with `svc #0` (lesson 05). On failure `x0` holds
  `-errno` (for example -2), and `errno` is not touched.

[`examples/syscalls.s`](examples/syscalls.s) prints a file with raw system calls:

```asm
    mov x0, #AT_FDCWD           // openat(AT_FDCWD, argv[1], O_RDONLY, 0)
    ldr x1, [x1, #8]            // argv[1]
    mov x2, #O_RDONLY
    mov x3, #0
    mov x8, #SYS_openat
    svc #0
    cmp x0, #0
    b.lt main_open_failed       // negative: x0 = -errno
```

and then loops: `read` up to 4096 bytes into a buffer in `.bss`, stop when
`read` returns 0, otherwise `write` exactly the number of bytes read. Reading in
a loop matters: one `read` gives you *at most* `n` bytes, never "the whole file".

```console
$ ./syscalls sample.txt
The quick brown fox
jumps over the lazy dog.
...
seven
$ ./syscalls nope.txt; echo $?
open failed: error 2
1
```

### Buffering

So why does stdio exist? Because system calls are slow compared to function
calls. `fputc` called a million times does *not* make a million system calls:
stdio collects bytes in a buffer inside the `FILE` and calls `write` once the
buffer is full. When the buffer is written out depends on the stream:

| Stream | Buffering | Flushed when |
|--------|-----------|--------------|
| `stdout` to a terminal | line buffered | a `'\n'` is written, buffer full, input is read, or exit |
| `stdout` to a file or pipe | fully buffered | the buffer (usually 4 KiB) is full, `fflush`, `fclose`, or exit |
| `stderr` | unbuffered | immediately |

Predict what this prints:

```c
printf("A");
write(1, "B\n", 2);
printf("C\n");
return 0;
```

[`examples/buffering.s`](examples/buffering.s):

```console
$ ./buffering
B
AC
```

`"A"` sits in stdout's buffer (no newline yet). The raw `write` goes straight to
fd 1. `"C\n"` joins `"A"` in the buffer, and returning from `main` calls
`exit`, which flushes it. Through a pipe the result is the same here, because
`exit` flushes in both cases.

Now the `streams` puzzle from section 5. Through `| cat`, stdout is a pipe, so
it is fully buffered: `to stdout\n` waits in the buffer until exit, while
unbuffered stderr prints at once. On a terminal the newline flushes stdout
first. And the `stdio_files` question: `fprintf` only filled a buffer; `fclose`
is what wrote it to the file. Read the file before that and you get nothing.

Rules of thumb:

- Do not mix stdio and raw `write` on the same fd, or call `fflush(stdout)`
  before the `write`.
- If your program crashes, buffered output is lost: it never reached `write`.
  When debugging with `printf`, end messages with `'\n'` or print to `stderr`.
- Calling `exit` (or returning from `main`) flushes; the raw `exit` system call
  (93) does not.

## 9. Three small tools

Now you have everything for three classic Unix programs. All of them read from
the files named on the command line, or from `stdin` if there are none, so they
work in pipes.

### `cat`

```c
void cat_stream(FILE *in) {
    int c;                              // int, not char: EOF is -1
    while ((c = fgetc(in)) != EOF)
        fputc(c, stdout);
}
```

`fgetc` returns the next byte as a value 0-255, or `EOF` (-1) at the end. That
is why the result is an `int`: all 256 byte values are valid data, so the
"no more data" signal has to be something else. In assembly, compare the whole
`w0` with -1 using `cmn` ("compare negative", which adds instead of subtracting,
so `cmn w0, #1` tests `w0 + 1 == 0`):

```asm
cat_stream_loop:
    mov x0, x19
    bl fgetc                        // w0 = next byte (0..255) or EOF (-1)
    cmn w0, #1                      // compare w0 with -1
    b.eq cat_stream_done
    mov x1, x20
    bl fputc                        // fputc(c, stdout); c is already in w0
    b cat_stream_loop
```

`main` in [`examples/cat.s`](examples/cat.s) calls `cat_stream(stdin)` when
`argc == 1`, otherwise opens each `argv[i]`. A file that cannot be opened gets a
`perror`, sets the status to 1, and the loop *continues* with the next file,
like the real `cat`. Because it copies bytes, not lines, it also copies binary
files exactly.

```console
$ ./cat sample.txt
The quick brown fox
...
$ printf 'piped\n' | ./cat
piped
$ ./cat nope.txt sample.txt > /dev/null; echo $?
nope.txt: No such file or directory
1
```

### `wc`

[`examples/wc.s`](examples/wc.s) counts bytes, lines (`'\n'` characters), and
words (runs of characters that are not space, tab, or newline). The word count
uses a flag: a word starts when you see a non-space while `inword` is 0.

```c
while ((c = fgetc(in)) != EOF) {
    bytes++;
    if (c == '\n') lines++;
    if (c == ' ' || c == '\t' || c == '\n') inword = 0;
    else if (!inword) { inword = 1; words++; }
}
```

Six values must survive every `fgetc` call (stream, three counters, flag,
`argv`), plus `argc`: that is seven callee-saved registers, `x19`-`x25`.

```console
$ ./wc sample.txt
12 24 117 sample.txt
$ printf 'one two\nthree\n' | ./wc
2 3 14
```

Compare with the real `wc sample.txt`.

### `head -n`

[`examples/head.s`](examples/head.s) prints the first N lines (default 10). It
shows the usual shape of option parsing: check `argv[i]` against `"-n"` with
`strcmp`, convert the next argument with `atoi`, skip both, and treat whatever
is left as a file name.

```c
int n = 10, i = 1;
if (i < argc && strcmp(argv[i], "-n") == 0) {
    if (i + 1 >= argc) { fputs("usage: head [-n N] [FILE]\n", stderr); return 2; }
    n = atoi(argv[i + 1]);
    i += 2;
}
```

It reads with `fgets` into a 256-byte stack buffer. A line longer than 255
characters comes back in pieces, so it counts a line only when the piece ends
in `'\n'`:

```asm
    add x0, sp, #BUF
    bl strlen                       // fgets never gives an empty string
    add x9, sp, #BUF
    add x9, x9, x0
    ldrb w10, [x9, #-1]             // buf[len - 1]
    cmp w10, #'\n'
    b.ne main_loop
    sub w21, w21, #1                // a whole line: n--
```

It also remembers `stdin` so it never `fclose`s it.

```console
$ ./head -n 3 sample.txt
The quick brown fox
jumps over the lazy dog.

$ ./head sample.txt | tail -n 1
five
$ printf 'a\nb\nc\n' | ./head -n 2
a
b
$ ./head -n; echo $?
usage: head [-n N] [FILE]
2
```

## C to assembly

| C | Linux AArch64 assembly |
|---|------------------------|
| `int main(int argc, char **argv, char **envp)` | `w0` = argc, `x1` = argv, `x2` = envp |
| `argv[i]` | `ldr x0, [x20, x21, lsl #3]` |
| `argv[argc] == NULL` | `ldr x0, [p]` then `cbz x0, done` |
| argc/argv at `_start` | `ldr x19, [sp]` / `add x20, sp, #8` |
| `getenv("NAME")` | `bl getenv`, then `cbz x0, unset` |
| `stdout` (the `FILE *`) | `adrp x8, :got:stdout` / `ldr x8, [x8, :got_lo12:stdout]` / `ldr x1, [x8]` |
| `fopen(path, "r")` | `x0` = path, `x1` = mode string, `bl fopen`, `cbz x0, failed` |
| `fprintf(f, fmt, v)` | `x0` = f, `x1` = fmt, `x2` = v, `bl fprintf` |
| `fgets(buf, n, f)` | `x0` = buf, `w1` = n, `x2` = f; `NULL` result means end |
| `(c = fgetc(f)) != EOF` | `bl fgetc` / `cmn w0, #1` / `b.eq eof` |
| `errno` | `bl __errno_location` / `ldr w0, [x0]` |
| `perror(s)` | `x0` = s, `bl perror` |
| `open(p, O_RDONLY)` | `bl open` (sets `errno`), or `openat` = 56 with `x0 = -100`, `svc #0` (returns `-errno`) |
| `read(fd, buf, n)` / `write` / `close` | `bl read` ..., or `x8` = 63 / 64 / 57, `svc #0` |
| `return 1;` from `main` | `mov w0, #1` before `ret` |

## Common mistakes

- **Treating `argv` as the first string.** `argv` is a pointer to pointers. You
  need two steps: `ldr x0, [x20, x21, lsl #3]` gets `argv[i]`, then you can read
  its bytes. Using `x1` itself as a string prints garbage.
- **Forgetting `argv[0]`.** Your arguments start at index 1. A loop from 0
  treats the program name as input (`./cat` would try to print itself).
- **Using `argv[1]` without checking `argc`.** If nobody passed it, `argv[1]`
  is `NULL` and `fopen(NULL, ...)` or `strcmp(NULL, ...)` crashes with a
  segmentation fault. Check `argc` first and print a usage message.
- **Not checking `NULL` from `fopen` or `getenv`.** The next call that uses the
  pointer crashes. Every `fopen` needs a `cbz x0, failed`.
- **Passing `&stdout` instead of `stdout`.** The GOT gives you the *address of
  the variable*; one more `ldr` gives its value. Missing it crashes inside
  `fputs`.
- **Storing `fgetc`'s result in a byte, or testing with `cmp w0, #255`.** EOF is
  -1 as an `int`; compare all 32 bits with `cmn w0, #1`.
- **Keeping the `FILE *`, counters, or `argv` in `x0`-`x15` across a call.**
  Every `bl` may destroy them. Use `x19`-`x28` and save them in the prologue.
- **Reading `errno` too late.** Any call between the failure and your read of
  `errno` (including `printf`) may change it. Read it first.
- **Expecting `errno` after a raw `svc #0`.** The raw call returns `-errno` in
  `x0` and leaves `errno` alone; `perror` will print a stale message.
- **Mixing `printf` and `write` and getting output out of order**, or losing
  output on a crash. That is buffering: add `\n`, use `fflush`, or use `stderr`.
- **Assuming one `read` reads the whole file.** It returns *up to* `n` bytes.
  Loop until it returns 0.
- **Overflowing a stack buffer.** `fgets` is safe because you pass the size;
  give it the real size of the buffer, not a bigger number.

## Recap

- `main` gets `argc` in `w0`, `argv` in `x1`, `envp` in `x2`. `argv[0]` is the
  program name and `argv[argc]` is `NULL`; `envp` ends with `NULL` too.
- At `_start` on Linux, `argc` is at `[sp]` and `argv` starts at `sp + 8`; libc's
  startup code turns that into a call to `main`.
- `getenv` returns a pointer into the environment, or `NULL`.
- `stdin`/`stdout`/`stderr` are `FILE *` variables inside libc; reach them
  through the GOT with `:got:` / `:got_lo12:` and one more load.
- `fopen`/`fgets`/`fgetc`/`fputs`/`fputc`/`fprintf`/`fclose` work on `FILE *`
  handles; `fopen` returns `NULL` on failure, `fgets` `NULL` at the end, `fgetc`
  `EOF` (-1) at the end.
- On failure, the reason is in `errno`; on Linux read it through
  `__errno_location()`, and `perror` prints it in the standard format.
- File descriptors are the layer below: `open`/`read`/`write`/`close`, as libc
  wrappers (return -1, set `errno`) or raw system calls (return `-errno`).
- stdio buffers output: line buffered on a terminal, fully buffered to files and
  pipes, `stderr` unbuffered. `fclose`, `fflush`, and `exit` flush.
- Exit 0 for success, 1 for failure, 2 for bad usage, and send error messages to
  `stderr`.

## Homework

Do the exercises in [exercises.md](exercises.md), then read the macOS companion
[../../apple-silicon/25-io-and-args/](../../apple-silicon/25-io-and-args/).
