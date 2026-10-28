# Toolchain

## What each tool does

| Step | Tool | Input | Output |
|------|------|-------|--------|
| Assemble | `as` (Linux) or `clang -c` | `prog.s` text | `prog.o` object file: machine code + unresolved names |
| Link | `ld`, usually driven by `gcc`/`clang` | `.o` files, libraries | executable |
| Inspect | `objdump -d`, `nm`, `readelf`/`otool` | object or executable | disassembly, symbol tables, headers |
| Debug | `gdb` (Linux), `lldb` (macOS) | executable | step through instructions, read registers and memory |

We almost always let `gcc` or `clang` run the assembler and linker for us,
because they know where the C library and startup files are.

## Linux flavor

Inside the container (`./scripts/linux-shell.sh`):

```console
$ gcc -g -nostdlib -static exit.s -o exit    # freestanding: defines _start
$ gcc -g hello.s -o hello                     # uses libc: defines main
$ gcc -S -O0 prog.c -o prog.s                 # see how gcc translates C
$ objdump -d prog                             # disassemble
$ gdb ./prog                                  # debug
```

## Apple flavor

On macOS with the Xcode command line tools (`xcode-select --install`):

```console
$ clang -g exit.s -o exit
$ clang -S -O0 prog.c -o prog.s
$ objdump -d prog
$ lldb ./prog
```

## Makefiles

Each `examples/` and `solutions/` directory has a two-line Makefile that
includes `mk/linux.mk` or `mk/apple.mk`. `make` builds every `.s` file into an
executable of the same name; `make clean` removes them.

## Online

[Compiler Explorer](https://godbolt.org) shows compiler output side-by-side with
C. Choose "ARM64 gcc" (Linux) or "armv8-a clang" and add `-O0` or `-O2`.
