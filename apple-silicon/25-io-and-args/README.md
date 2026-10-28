# Lesson 25 (macOS): I/O and arguments

Do [lesson 25 in the main track](../../lessons/25-io-and-args/) first. This page
covers only what is different on macOS, then walks through each macOS example.

```console
$ cd apple-silicon/25-io-and-args/examples
$ make
```

## What is different

| Topic | Linux | macOS |
|-------|-------|-------|
| Where argc/argv come from | `main(w0, x1, x2)`; at `_start`, on the stack | `_main(w0, x1, x2)` only: there is no `_start` of your own |
| Extra `main` argument | none | a fourth, `char **apple` in `x3` (system info for libSystem; ignore it) |
| `stdin` / `stdout` / `stderr` | `stdin`, `stdout`, `stderr` | C macros for `__stdinp`, `__stdoutp`, `__stderrp`: in assembly `___stdinp` etc. |
| GOT access | `adrp x8, :got:stdout` / `ldr x8, [x8, :got_lo12:stdout]` | `adrp x8, ___stdoutp@GOTPAGE` / `ldr x8, [x8, ___stdoutp@GOTPAGEOFF]` |
| `errno` | `__errno_location()` | `__error()`, in assembly `___error` |
| `printf`/`fprintf` values | in registers after the format | **on the stack**, 8 bytes each, after the format |
| `open(path, flags, mode)` | `mode` in `w2` | `open` is variadic: `mode` goes **on the stack** |
| `O_CREAT` / `O_TRUNC` | `0x40` / `0x200` | `0x200` / `0x400` (see `<sys/fcntl.h>`) |
| Raw system calls | stable: `openat` = 56, `read` = 63, ... with `svc #0`; error = negative `x0` | not a stable ABI: call `_open`, `_read`, `_write`, `_close` instead |
| Strings in `__TEXT,__cstring` | `.rodata` may hold `.ascii` data | must be NUL-terminated (`.asciz`) |

### There is no `_start` for you

On macOS the kernel starts `dyld`, the dynamic loader, which sets up libSystem
and then calls your `_main`. The stack layout at process entry is similar (argc,
then the argv pointers), but you never see it: a program without libSystem
cannot be linked. So `argc`, `argv`, and `envp` always arrive the way C says, in
`w0`, `x1`, `x2`. macOS also passes a fourth array, `apple`, in `x3`; it holds
strings for the system (such as the executable path). Leave it alone.

### `stdout` is `___stdoutp`

Apple's `<stdio.h>` says

```c
extern FILE *__stdoutp;
#define stdout __stdoutp
```

so the variable your assembly needs is `__stdoutp`, plus the usual leading
underscore: `___stdoutp` (three underscores). It lives in libSystem, so you
reach it through the GOT, and then load the value, exactly as on Linux:

```asm
    adrp x8, ___stdoutp@GOTPAGE
    ldr x8, [x8, ___stdoutp@GOTPAGEOFF] // x8 = &__stdoutp
    ldr x1, [x8]                        // x1 = stdout (the FILE *)
```

The same goes for `___stdinp` and `___stderrp`.

### `errno` is `___error`

`errno` is per-thread here too. The function that returns its address is
`int *__error(void)`, so you call `bl ___error` and then `ldr w0, [x0]`.

### Variadic arguments on the stack, now with `fprintf` and `open`

As in lesson 16, everything after the last named parameter of a variadic
function goes on the stack. For `fprintf(f, fmt, ...)` that means `f` and `fmt`
stay in `x0` and `x1`, and the values go at `[sp]`, `[sp, #8]`, ... Every
example makes the room right around the call:

```asm
    sub sp, sp, #16             // room for the variadic arguments (keep sp 16-aligned)
    str x20, [sp]               // first value
    bl _fprintf
    add sp, sp, #16             // give it back
```

Three or four values need 32 bytes (24 rounds up to 32).

The surprise in this lesson is `open`. Its prototype is

```c
int open(const char *path, int flags, ...);
```

The mode is a variadic argument, because you only pass it with `O_CREAT`. On
Linux it simply goes in `w2`; on macOS it must go on the stack. Put it in `w2`
and `open` reads whatever happens to be at `[sp]` as the permissions: your new
file gets random permission bits.

### No raw system calls

Lesson 05 showed raw BSD system calls (`x16`, `svc #0x80`), which also report
errors differently: the carry flag is set and `x0` holds the positive errno.
Apple does not promise that interface stays the same, so real macOS programs
call the libSystem wrappers `_open`, `_read`, `_write`, `_close`. They make one
system call each, with no buffering, so everything the main lesson says about
buffered versus unbuffered I/O holds. On failure they return -1 and set `errno`.

### `__cstring` holds C strings only

The linker treats `__TEXT,__cstring` as a list of NUL-terminated strings that it
may merge. A `.ascii "B\n"` with no terminator runs into the next string, and
`ld` warns "c-string symbol ... is located within another string". Use
`.asciz` there even when you pass an explicit length to `write`.

## The examples

### `args.s`

Same loop as Linux. The two `printf` values move to the stack:

```asm
    ldr x9, [x20, x21, lsl #3]  // argv[i]
    sub sp, sp, #16
    str x21, [sp]               // first variadic argument: i
    str x9, [sp, #8]            // second variadic argument: argv[i]
    bl _printf
    add sp, sp, #16
```

```console
$ ./args hello "two words" 3
argc = 4
argv[0] = ./args
argv[1] = hello
argv[2] = two words
argv[3] = 3
```

### `start_args.s`

The Linux version reads argc and argv off the stack at `_start`. Here it is a
`_main` that gets them in `w0`/`x1`, and calls `_write` instead of `svc`. The
output and exit status are the same:

```console
$ ./start_args red green; echo $?
./start_args
red
green
3
```

### `envp.s` and `getenv.s`

`envp` is in `x2`, and walking it is identical. `getenv` is `_getenv`; the
`%s` value goes on the stack before `_printf`.

```console
$ env -i A=1 B=two ./envp
A=1
B=two
2 variables
$ GREETING=hello ./getenv
GREETING is hello
$ env -u GREETING ./getenv
GREETING is not set
```

### `streams.s`

Uses `___stdoutp` and `___stderrp` through `@GOTPAGE`/`@GOTPAGEOFF`. Output is
the same, including the reversed order through a pipe:

```console
$ ./streams; echo $?
to stdout
to stderr
3
$ ./streams 2>/dev/null
to stdout
```

### `stdio_files.s`

`_fopen`, `_fgets`, `_fclose` take only named arguments, so they are called
exactly as on Linux. `_fprintf` keeps the stream and format in `x0`/`x1` and
puts `i` at `[sp]`:

```console
$ ./stdio_files
read: line 1
read: line 2
read: line 3
```

### `errno.s`

`bl ___error` instead of `bl __errno_location`, and the saved `errno` goes on
the stack for `_printf`:

```console
$ ./errno 2>&1; echo $?
no-such-file.txt: No such file or directory
errno = 2
1
```

### `syscalls.s`

The Linux version uses raw `openat`/`read`/`write`/`close`. This one calls the
wrappers. Opening for reading needs no mode, so nothing goes on the stack. On
failure the reason comes from `errno`, not from a negative return value:

```asm
    ldr x0, [x1, #8]            // open(argv[1], O_RDONLY)
    mov w1, #O_RDONLY
    bl _open
    cmp w0, #0
    b.lt main_open_failed       // -1: the reason is in errno
```

```console
$ ./syscalls sample.txt
The quick brown fox
...
$ ./syscalls nope.txt; echo $?
open failed: error 2
1
```

### `buffering.s`

`_write` replaces the raw `svc`. It is still unbuffered, so the result is the
same:

```console
$ ./buffering
B
AC
```

### `cat.s`, `wc.s`, `head.s`

`cat` and `head` only change names (`_fgetc`, `_fputc`, `_fgets`, `_strcmp`,
`_atoi`) and use `___stdinp`/`___stdoutp`/`___stderrp`. `wc` prints three or
four values, so it reserves 32 bytes and stores them with `stp`:

```asm
    ldr x9, [x24, #8]               // argv[1]
    sub sp, sp, #32                 // four variadic arguments: 32 bytes
    stp x20, x21, [sp]              // lines, words
    stp x22, x9, [sp, #16]          // bytes, argv[1]
    bl _printf
    add sp, sp, #32
```

```console
$ ./cat sample.txt | head -n 2
The quick brown fox
jumps over the lazy dog.
$ ./wc sample.txt
12 24 117 sample.txt
$ ./head -n 3 sample.txt
The quick brown fox
jumps over the lazy dog.

```

## Exercises

Do the exercises in the main lesson's
[exercises.md](../../lessons/25-io-and-args/exercises.md) as macOS programs.
macOS solutions are in [solutions/](solutions/); the written answers are in the
main track's [solutions/README.md](../../lessons/25-io-and-args/solutions/README.md).
Things to watch:

- 25.6 (`cp`): use the macOS flag values (`O_CREAT` = `0x200`, `O_TRUNC` =
  `0x400`) and pass the mode `0644` on the stack. Check with `ls -l copy.txt`:
  it should say `-rw-r--r--`.
- 25.4, 25.9: every `printf` value goes on the stack.
- Every `stdin`/`stdout`/`stderr` is `___stdinp`/`___stdoutp`/`___stderrp`.
