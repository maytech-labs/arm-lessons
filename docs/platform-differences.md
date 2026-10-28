# Linux AArch64 vs Apple Silicon (macOS arm64)

The CPU instructions are identical. What differs is everything *around* them: the
operating system, the object file format, the assembler's dialect for a few
things, and some details of the calling convention. This page is the master list;
each `apple-silicon/NN-*` lesson explains the parts relevant to that lesson.

| Topic | Linux AArch64 | macOS arm64 |
|-------|---------------|-------------|
| Object / executable format | ELF | Mach-O |
| Symbol names | as written: `main`, `printf` | prefixed with `_`: `_main`, `_printf` |
| Entry point of our programs | `_start` (freestanding) or `main` (libc) | always `_main` (libSystem is always linked) |
| Build command | `gcc prog.s -o prog` (add `-nostdlib -static` for `_start`) | `clang prog.s -o prog` |
| System call number register | `x8` | `x16` |
| System call instruction | `svc #0` | `svc #0x80` |
| System call error report | `x0` = negative errno | carry flag set, `x0` = positive errno |
| `exit` / `read` / `write` numbers | 93 / 63 / 64 | 1 / 3 / 4 |
| Registers a system call changes | only `x0` | `x0` and `x1` (and the carry flag) |
| Raw system calls | stable, documented ABI | work, but *not* a stable ABI; real code calls libSystem |
| Address of a symbol | `adrp x0, sym` + `add x0, x0, :lo12:sym` | `adrp x0, sym@PAGE` + `add x0, x0, sym@PAGEOFF` |
| Address via GOT (e.g. `stdout`) | `adrp x0, :got:sym` + `ldr x0, [x0, :got_lo12:sym]` | `adrp x0, _sym@GOTPAGE` + `ldr x0, [x0, _sym@GOTPAGEOFF]` |
| Read-only data section | `.section .rodata` | `.section __TEXT,__const`; NUL-terminated strings only may go in `__TEXT,__cstring` |
| Tables of absolute addresses | any section (in `.text`/`.rodata` the binary gets `TEXTREL`) | must be in `__DATA` (`.data` or `__DATA,__const`); `__TEXT` fails with "illegal text-relocations" |
| `.equ` used before definition | accepted | rejected as an immediate: define `.equ`s first |
| `.equ N, (. - a) / 4` (a size from label addresses) as an immediate | accepted everywhere | accepted by `mov`, rejected by `cmp`/`add`/`sub`: `mov` it into a register first |
| `.data`, `.text` | supported | supported |
| Zero-initialised data | `.bss` + `.space` | `.zerofill __DATA,__bss,sym,size,align` (or `.bss` + `.space`) |
| Labels named like registers (`d1`, `s2`, `b3`, `q0`) | accepted | rejected as branch targets: never name a label after a register |
| SIGBUS exit status | 135 (signal 7) | 138 (signal 10) |
| `.type`, `.size` directives | ELF only | not supported, leave them out |
| Register `x18` | free temporary | **reserved by the OS: never touch** |
| Variadic arguments (`printf`) | passed in registers like normal arguments | **every variadic argument goes on the stack**, 8 bytes each |
| Non-variadic stack arguments | each in an 8-byte slot | packed at their natural size and alignment |
| `char` | unsigned | signed |
| `long double` | 128-bit IEEE quad | same as `double` |
| Arguments narrower than 32 bits | upper bits unspecified | caller sign/zero-extends to 32 bits |
| Red zone below `sp` | none | 128 bytes |
| `open` mode argument | in `x2` | `open` is variadic: mode goes on the stack |
| `O_CREAT` / `O_TRUNC` | `0x40` / `0x200` | `0x200` / `0x400` |
| `MAP_ANONYMOUS` | `0x20` | `MAP_ANON` = `0x1000` |
| Page size | 4 KiB | 16 KiB |
| `main` arguments | `argc`, `argv`, `envp` | also a fourth, `apple`, in `x3` |
| `errno` location | `__errno_location()` | `__error()` (symbol `___error`) |
| `stdout` / `stderr` symbols | `stdout`, `stderr` | `___stdoutp`, `___stderrp` |
| Static linking | `-static` works | not supported |
| Double free | glibc aborts (status 134) | SIGTRAP (status 133), often silently |
| Leak checking | `-fsanitize=address` (LeakSanitizer) | `leaks --atExit -- ./prog` |
| Timer frequency (`cntfrq_el0`) | 24 MHz in the container on Apple Silicon | 1 GHz on recent macOS / chips: always read it |
| Pointer authentication in compiler output | `paciasp`/`autiasp` with `-mbranch-protection` | none for `arm64`; `pacibsp`/`retab` for `arm64e` (system binaries) |
| Debugger | `gdb` | `lldb` |
| Disassembler | `objdump -d` | `objdump -d` or `otool -tv` |
| Inspect a binary | `readelf`, `file`, `nm` | `otool -l`, `file`, `nm` |
| Trace system calls | `strace` | `dtruss` (needs SIP changes; rarely worth it) |

## Things that are the same

- All instructions, registers (except the `x18` rule), condition codes, addressing modes.
- `x0`-`x7` carry arguments, `x0` returns, `x19`-`x28` are callee-saved, `x29` is
  the frame pointer, `x30` the link register, `sp` must be 16-byte aligned.
- `//` comments, `.global`, `.text`, `.data`, `.ascii`, `.asciz`, `.byte`,
  `.hword`, `.word`, `.quad`, `.p2align`, `.equ`, `.macro`.
- Little-endian byte order.

## Running the Linux track on a Mac

Apple Silicon runs arm64 Linux containers natively, with no emulation:

```console
$ ./scripts/linux-shell.sh
root@...:/work# cd lessons/04-first-program/examples && make
```
