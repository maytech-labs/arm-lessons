# Lesson 00 on macOS: Setup

Read [the main lesson](../README.md) first. This page
covers only what is different when you build and run natively on your Mac.

## No container needed

The Apple Silicon flavor runs directly in macOS Terminal. You only need the Xcode
command line tools from step 1 of the main lesson:

```console
$ xcode-select --install
$ clang --version
Apple clang version ...
Target: arm64-apple-darwin...
```

In `apple-silicon/`, a `$` prompt means your normal macOS Terminal, never the
container.

## Building and running the example

```console
$ cd lessons/00-setup/apple-silicon/examples
$ make
clang -g -arch arm64 -o check check.s
$ ./check
toolchain works
$ echo $?
0
```

The Makefile here includes `mk/apple.mk` instead of `mk/linux.mk`. It runs
`clang` instead of `gcc`. Same idea: every `foo.s` becomes a program `foo`, and
`make clean` removes them.

## The macOS version of `check.s`

Open [examples/check.s](examples/check.s) next to the Linux one,
[../linux/examples/check.s](../linux/examples/check.s).
The instructions that do the work (`mov`, `svc`, `adrp`, `add`) are the same
CPU instructions. A few details differ, and lessons 04 and 05 explain each:

| Linux | macOS | Why (lesson) |
|-------|-------|--------------|
| `_start:` | `_main:` | where the program begins (04) |
| `mov x8, #93` / `svc #0` | `mov x16, #1` / `svc #0x80` | how you ask the OS to exit (04) |
| `mov x8, #64` | `mov x16, #4` | how you ask the OS to write (05) |
| `adrp x1, msg` / `add x1, x1, :lo12:msg` | `adrp x1, msg@PAGE` / `add x1, x1, msg@PAGEOFF` | how you write an address (05) |

One more difference to know from day one: these programs talk to the macOS
kernel directly with `svc #0x80`. That works, but Apple does not promise it
will keep working; real macOS programs go through Apple's C library
(libSystem). Until lesson 16 we use the direct route anyway, because it lets
you see everything. From lesson 16 on, both flavors call the C library.

## Looking inside a macOS program

The same three tools exist on the Mac, with different-looking output.

```console
$ file check
check: Mach-O 64-bit executable arm64
```

**Mach-O** is the macOS program format (Linux uses ELF). `arm64` is Apple's
name for AArch64.

```console
$ nm check
0000000100000000 T __mh_execute_header
0000000100000370 T _main
0000000100004000 d msg
```

macOS programs start at much higher addresses than Linux ones (lesson 03),
and the linker adds `__mh_execute_header` instead of Linux's `__bss_start`
and friends.

```console
$ objdump -d check

check:	file format mach-o arm64

Disassembly of section __TEXT,__text:

0000000100000370 <_main>:
100000370: d2800020    	mov	x0, #0x1                ; =1
100000374: 90000021    	adrp	x1, 0x100004000 <msg>
100000378: 91000021    	add	x1, x1, #0x0
...
```

The first line, `d2800020 mov x0, #0x1`, is *byte for byte* the same
instruction as on Linux. Apple's `objdump` uses `;` for its comments where
Linux uses `//`. macOS also has `otool -tv check`, which shows the same thing
in Apple's older format.

## A difference you can see: macOS always links the C library

```console
$ otool -L check
check:
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version ...)
```

Even though `check.s` never calls the C library, the macOS program is linked
against it. macOS has no equivalent of Linux's `-nostdlib -static`: every
program is started by Apple's loader and linked with libSystem. That is why
macOS programs begin at `_main` (a function the system calls) instead of
`_start`. Lesson 04 says more.

## Exercises on macOS

Do the exercises in [../exercises.md](../exercises.md)
natively, in `lessons/00-setup/apple-silicon/work/` with a copy of
`lessons/00-setup/apple-silicon/examples/Makefile`. Use the macOS `check.s` as your
starting point. Differences to expect:

- **00.1**: parts 1 and 2 only; parts 3 and 4 are about the container. You can
  run `uname -sm` on the Mac too: it says `Darwin arm64` (Darwin is the core
  of macOS).
- **00.3, 00.4**: same edits, made to the macOS `check.s`. Solutions:
  [solutions/ex3.s](solutions/ex3.s), [solutions/ex4.s](solutions/ex4.s).
- **00.5**: `file check` says `Mach-O 64-bit executable arm64`.
- **00.6**: look for `_main` instead of `_start`. `msg` again has the bigger
  address.
- **00.7**: nine instructions, 4 bytes apart, as on Linux. `mov x0, #0x0` is
  `d2800000` on both systems, and `mov x0, #0x7` is `d28000e0` on both.
- **00.8**: build with `clang hello.c -o hello`. This time the two programs
  are about the same size (about 33 KB; macOS pads programs out), and
  `otool -L` shows both use libSystem. `nm hello` shows `U _printf`: `U`
  means "undefined here, found in a library when the program starts".

## Common mistakes

- **Running `make` in `lessons/` on the Mac.** Those Makefiles are for Linux;
  you get errors such as `ADR/ADRP relocations must be GOT relative`. Build
  `lessons/` in the container and `apple-silicon/` on the Mac.
- **`xcrun: error: invalid active developer path`.** The command line tools
  are not installed (or a macOS update removed them). Run
  `xcode-select --install` again.
