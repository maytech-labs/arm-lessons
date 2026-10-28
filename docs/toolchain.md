# Toolchain

## What each tool does

| Step | Tool | Input | Output |
|------|------|-------|--------|
| Assemble | `as` (Linux) or `clang -c` | `prog.s` text | `prog.o` object file: machine code + unresolved names |
| Link | `ld`, usually driven by `gcc`/`clang` | `.o` files, libraries | executable |
| Inspect | `objdump -d`, `nm`, `readelf`/`otool` | object or executable | disassembly, symbol tables, headers |
| Debug | `gdb` (Linux), `lldb` (macOS) | executable | step through instructions, read registers and memory |
| Check and lint | `armls` (editor), `armtool` (terminal), from [arm-tools](https://github.com/maytech-labs/arm-tools) | `prog.s` text | errors and ABI mistakes, before you build |

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

## arm-tools (recommended)

Optional, and installed on the Mac (setup is in
[lesson 00](../lessons/00-setup/README.md#recommended-arm-tools)):

```console
$ armtool check lessons/07-arithmetic/linux/work   # errors, as the assembler reports them
$ armtool lint lessons/07-arithmetic/linux/work    # plus ABI and control-flow mistakes
$ armtool explain abi/callee-saved                 # what a rule means
```

The tools read the nearest `armtool.toml` above each file, and the nearest
one wins outright, with no merging. The root `armtool.toml` covers the
`apple-silicon/` folders (Darwin is armtool's default). Each
`lessons/NN-*/linux/` folder has its own `armtool.toml` that selects Linux,
turns off the ELF bookkeeping rules the course doesn't use, and repeats the
root's `[format]`. Add one when you add a lesson with a `linux/` folder.

## Online

[Compiler Explorer](https://godbolt.org) shows compiler output side-by-side with
C. Choose "ARM64 gcc" (Linux) or "armv8-a clang" and add `-O0` or `-O2`.
