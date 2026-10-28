# Lesson 20 on macOS: Symbols, sections, and multi-file programs

Read [the main lesson](../../lessons/20-symbols-and-sections/README.md) first.
Global and local symbols, `static`, multi-file linking, numbered local labels,
`.macro`, `.include`, `.rept`, and `.set` all work **the same** on your Mac.
What differs is the naming of sections and some messages.

```console
$ cd apple-silicon/20-symbols-and-sections/examples && make
$ ./sections
code < constants: yes
constants < data: yes
data < bss: yes
bss < stack: yes
counter = 5, buffer[0] = 0
$ ./app
square(7) = 49, cube(3) = 27, calls = 2
```

## Sections in Mach-O

| ELF (Linux) | Mach-O (macOS) | Segment permissions |
|-------------|----------------|---------------------|
| `.text` | `__TEXT,__text` | read + execute |
| `.rodata` | `__TEXT,__const` (and `__TEXT,__cstring` for strings) | read + execute |
| `.data` | `__DATA,__data` | read + write |
| `.bss` | `__DATA,__bss` | read + write |

Constants live in the **`__TEXT` segment**, next to the code. That is why a
table of *addresses* cannot be there (the loader would have to write into
`__TEXT`): put it in `.data`, as `solutions/ex7.s` does.

`objdump -h sections` lists them; `otool -l sections` shows the segments with
their permissions.

## Writing to constants is a bus error

```console
$ ./const_write; echo $?
138
```

On Linux, writing to `.rodata` is a segmentation fault (139). macOS reports a
write to a read-only mapped page as `SIGBUS` (signal 10, status 138). Same
bug, different signal.

## `nm` on macOS

```console
$ make app.o mathlib.o && nm app.o mathlib.o
app.o:
0000000000000000 T _main
                 U _printf
                 U cube
0000000000000064 s fmt
0000000000000000 t ltmp0
...
mathlib.o:
000000000000001c T cube
0000000000000058 D mathlib_calls
000000000000004c t mul3
0000000000000000 T square
```

- C-visible names have the underscore (`_main`, `_printf`). `cube`, `square`,
  and `mathlib_calls` have none, because only assembly files use them, and
  both files spell them the same way.
- `s` means "some other section" (here `__TEXT,__const`).
- `ltmp0`, `ltmp1`, ... are temporary labels the assembler adds at the start of
  each section; ignore them.

## Error messages

| Mistake | macOS linker says |
|---------|-------------------|
| a name nobody exports | `Undefined symbols for architecture arm64: "cube", referenced from: _main in app-....o` |
| a name exported twice | `duplicate symbol 'square' in: ...` |
| non-zero data in `.bss` | `error: virtual section '__bss' cannot have non-zero initializers` |

## Macros

`macros.inc` differs only in the address-loading macro:

```asm
    .macro LOAD_ADDR reg, sym
    adrp \reg, \sym@PAGE
    add \reg, \reg, \sym@PAGEOFF
    .endm
```

A macro that calls `printf` must store its variadic argument on the stack, as
every macOS `printf` call does (see `solutions/ex5.s`).

## Exercises

Do the [main lesson's exercises](../../lessons/20-symbols-and-sections/exercises.md)
as macOS programs. The answers are the same, with the messages above for
20.6. In 20.2, the still-undefined `_printf` is resolved from libSystem when
the program is loaded. macOS solutions are in [solutions/](solutions/).
