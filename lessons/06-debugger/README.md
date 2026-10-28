# Lesson 06: The debugger

## Goals

After this lesson you can:

- Start a program under `gdb` and stop it at its first instruction.
- Step one instruction at a time and watch registers change.
- Print a register in decimal, hex, binary, or as a character.
- Examine memory as bytes, words, characters, and strings.
- Set breakpoints on labels and continue to them.
- Change a register while the program is paused.
- Use all of this to find a bug you cannot see by reading the code.

## Before you start

You need lessons 04 and 05. Use the container (it is started with the
permissions `gdb` needs):

```console
$ ./scripts/linux-shell.sh
# cd lessons/06-debugger/linux/examples && make
```

## Why a debugger, and why now

So far your programs have had two ways to tell you anything: the exit status
and `write`. Neither tells you what is going on *inside*: what is in `x3`
right now? Did that `add` do what you meant?

A debugger runs your program under its control. It can stop it at any
instruction, show you every register and any byte of memory, and let you go
forward one instruction at a time. In assembly you will use it constantly, so
learn it before the programs get bigger.

Our programs are built with `-g`, which records which source line each
instruction came from. That lets `gdb` show your own lines and comments.

## Starting: `starti` and `si`

`examples/regs.s` is a handful of `mov`s ending in `exit(42)`. Start it:

```console
# gdb -q ./regs
Reading symbols from ./regs...
(gdb) starti
Program stopped.
_start () at regs.s:14
14	    mov x0, #1                  // x0 = 1
```

- `gdb -q ./regs` loads the program but does not run it (`-q` skips the banner).
- `starti` ("start, stop at the first instruction") runs the program and pauses
  it **before** the first instruction executes.

The line shown is the *next* instruction to run. It has not run yet.

Now step:

```console
(gdb) si
15	    mov x1, #2                  // x1 = 2
(gdb) si
16	    mov x2, #0xff               // x2 = 255
```

`si` ("step instruction") executes exactly one instruction. `si 3` executes
three. Pressing Enter on an empty line repeats the last command, so you can
type `si` once and then just keep hitting Enter.

## Reading registers

```console
(gdb) p $x1
$1 = 2
(gdb) p/x $x2
$2 = 0x0
```

`p` (print) shows a value. Registers are written with a `$`. `x2` is still 0
because the `mov x2, #0xff` has not run yet: line 16 is *next*.

The `/x` is a **format**:

| Format | Shows | Example for 255 |
|--------|-------|-----------------|
| `p $x2` | decimal | `255` |
| `p/x $x2` | hex | `0xff` |
| `p/t $x2` | binary | `11111111` |
| `p/c $x2` | character (low byte only) | `-1 '\377'` (255 is not a printable character) |
| `p/d $x2` | signed decimal | `255` |

To see several registers at once:

```console
(gdb) si 3
19	    mov x0, #42                 // x0 = 42, the exit status
(gdb) info registers x0 x1 x2 x3 x4
x0             0x1                 1
x1             0x2                 2
x2             0xff                255
x3             0xff                255
x4             0x7                 7
```

`info registers` with no names shows all of them, including `sp`, `pc`, and
`cpsr` (the flags, lesson 09). `i r` is the short form.

Before you step, **predict**. Before `si` past `mov x3, x2`, say "x3 will
become 255". Then check. That habit is the fastest way to learn.

## Seeing the instructions

```console
(gdb) x/3i $pc
=> 0x4000d4 <_start>:	mov	x0, #0x1                   	// #1
   0x4000d8 <_start+4>:	mov	x1, #0x2                   	// #2
   0x4000dc <_start+8>:	mov	x2, #0xff                  	// #255
```

`x/3i $pc` means "examine 3 instructions starting at the program counter". The
`=>` marks the next one to run. `disassemble` shows the whole current
function. Notice that the addresses go up by 4: every instruction is 4 bytes.

Your addresses may differ from the ones shown here. That is fine.

## Examining memory: `x`

`p` shows *values*. `x` shows *memory*, starting at an address. Its form is
`x/NFU address`: **N** units, in format **F**, of size **U**.

| Size letter | Unit |
|-------------|------|
| `b` | byte (1) |
| `h` | halfword (2) |
| `w` | word (4) |
| `g` | giant: doubleword (8) |

| Format letter | Shows |
|---------------|-------|
| `x` | hex |
| `d` | decimal |
| `c` | characters |
| `s` | a zero-terminated string |
| `i` | instructions |

Run `hello` up to the `write`:

```console
# gdb -q ./hello
(gdb) break _start
Breakpoint 1 at 0x40010c: file hello.s, line 18.
(gdb) run
Breakpoint 1, _start () at hello.s:18
(gdb) si 3
21	    mov x2, #msg_len            // x2 = number of bytes to write
(gdb) x/s $x1
0x410130:	"Hello, world!\n"
(gdb) x/14xb $x1
0x410130:	0x48	0x65	0x6c	0x6c	0x6f	0x2c	0x20	0x77
0x410138:	0x6f	0x72	0x6c	0x64	0x21	0x0a
(gdb) x/14c $x1
0x410130:	72 'H'	101 'e'	108 'l'	108 'l'	111 'o'	44 ','	32 ' '	119 'w'
0x410138:	111 'o'	114 'r'	108 'l'	100 'd'	33 '!'	10 '\n'
```

`x1` holds an address, and `x` shows what lives there. These are exactly the
bytes `.ascii` put in memory in lesson 05.

`x/s` works here because the bytes after our message happen to be zero. It
reads until it finds a zero byte, so on an `.ascii` string with no zero it may
show extra junk.

Step over the `svc` and look at the result:

```console
(gdb) si 3
Hello, world!
25	    mov x0, #0                  // exit status 0
(gdb) p $x0
$1 = 14
```

The output appeared when the `svc` ran, and `x0` now holds `write`'s result:
14 bytes written.

### Byte order, seen directly

`examples/bytes.s` stores `.quad 0x1122334455667788`. Look at it two ways:

```console
(gdb) starti
(gdb) si 2
(gdb) x/2gx $x1
0x410128:	0x1122334455667788	0x000000000000002a
(gdb) x/8xb $x1
0x410128:	0x88	0x77	0x66	0x55	0x44	0x33	0x22	0x11
```

As one 8-byte number, it reads `0x1122334455667788`. As eight separate bytes,
the **lowest** byte `0x88` comes first. This is little-endian order from
lesson 02, now in front of you. You can also name a label directly:
`x/4xb &small`.

## Breakpoints

`starti` stops at the very beginning. In a longer program you want to stop at
a particular place. A **breakpoint** does that:

```console
(gdb) break _start          # or: b _start
(gdb) run                   # or: r; runs until a breakpoint (or the end)
(gdb) continue              # or: c; runs on to the next breakpoint
(gdb) info breakpoints      # list them
(gdb) delete 1              # remove breakpoint 1
```

You can break on any label, so **adding a label is a cheap way to mark a spot
you want to inspect**. Labels cost nothing in the program. You can also
break on a line: `break hello.s:23`.

## Watching as you go

Typing `info registers` after every step gets old. `display` re-prints an
expression every time the program stops:

```console
(gdb) display/x $x0
(gdb) display/x $x1
(gdb) si
```

For a full-screen view, try `layout asm` and `layout regs` (the text user
interface). `Ctrl-x a` toggles it off again. It can garble a small terminal;
`Ctrl-l` redraws.

## Changing things

You can change registers (and memory) while paused:

```console
(gdb) set $x0 = 7
```

Stop at the final `svc` of any program, set `x0`, and `continue`: the program
exits with your number instead. This is a quick way to test "what if this
register had held something else?" without editing and rebuilding.

## Finding a bug

`examples/broken.s` should print `Hi!` but prints nothing. Read it first. Do
you see the bug? Whether you do or not, find it with the debugger:

```console
# ./broken; echo $?
0
# gdb -q ./broken
(gdb) starti
(gdb) si 5
25	    svc #0                      // write(?, ?, 4)
(gdb) info registers x0 x1 x2
x0             0x410130            4260144
x1             0x1                 1
x2             0x4                 4
```

Stopped just before the `write`, compare the registers with what `write`
needs: fd in `x0`, address in `x1`, count in `x2`. `x0` holds an address
(`x/s $x0` shows `"Hi!\n"`), and `x1` holds 1. They are swapped. `write` was
asked to write to file descriptor 4260144, which does not exist, so it failed
and printed nothing (`p $x0` after the `svc` would show a negative error code).

This is the debugging method you will use for the rest of the course:

1. Decide what the registers *should* hold at some point.
2. Stop there.
3. Look. The first place where reality differs from your expectation is
   where the bug is.

## Quitting

`quit` (or `q`, or `Ctrl-d`). If the program is still running, `gdb` asks you
to confirm.

## Command summary

| Command | Short | Does |
|---------|-------|------|
| `starti` | | run, stop before the first instruction |
| `break LABEL` | `b` | stop when reaching LABEL |
| `run` | `r` | run from the start |
| `continue` | `c` | run to the next breakpoint |
| `stepi` | `si` | execute one instruction (`si N`: N instructions) |
| `info registers` | `i r` | show registers |
| `p/FMT $reg` | | print a register in a format |
| `x/NFU addr` | | examine memory |
| `display/FMT expr` | | show expr at every stop |
| `disassemble` | | show the current function's instructions |
| `set $reg = value` | | change a register |
| `quit` | `q` | leave |

`nexti` (`ni`) is like `si` but steps *over* function calls; it will matter
from lesson 14.

## C to assembly

There is no C in this lesson, but here is how debugging C and assembly compare:

| Debugging C | Debugging assembly |
|-------------|--------------------|
| `next` / `step` (one source line) | `si` (one instruction) |
| `p variable` | `p $x3`: you know which register holds which variable |
| `p *ptr`, `p arr[2]` | `x/xg $x1`, `x/xw $x1+8` |
| break on a function | break on any label |

## Common mistakes

- **Thinking the shown line has already run.** It is the *next* line to run.
- **Using `x` when you meant `p`.** `x $x0` treats `x0` as an address and
  shows memory there. `p $x0` shows the value in `x0`.
- **Forgetting the `$`.** `p x0` looks for a variable called `x0` and fails.
- **Wrong unit size.** `x/2xw` and `x/2xg` show very different things. Say the
  size you mean every time.
- **`run` without a breakpoint.** The program runs to the end and exits; there
  is nothing to look at. Use `starti` or set a breakpoint first.
- **`gdb` complains about ptrace or personality.** You are running the
  container without the options `scripts/linux-shell.sh` adds. Use the script.

## Recap

- `gdb ./prog`, then `starti` to pause before the first instruction.
- `si` executes one instruction; the shown line is the next one to run.
- `p/x $reg` prints a register; `info registers` shows many.
- `x/NFU addr` examines memory: units `b h w g`, formats `x d c s i`.
- `break LABEL`, `run`, `continue`; add labels to mark interesting spots.
- `display` re-prints at every stop; `set $reg = v` changes a register.
- Debugging = predict what should be there, stop, look, find the first
  difference.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next: it
teaches the same things in `lldb`.
