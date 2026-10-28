# The Apple Silicon flavor (macOS arm64)

The instructions your M-series CPU runs are exactly the ones in the Linux
flavor.
What changes on macOS is the plumbing around them: the executable format,
symbol names, system calls, how addresses are written in the assembly, one
reserved register, and how variadic functions like `printf` receive arguments.

## How to use this flavor

1. Read lesson `NN`'s `README.md` in [`../lessons/`](../lessons/) first.
2. Read the lesson's `apple-silicon/README.md`: it explains only what differs,
   and walks through the macOS version of each example.
3. Build and run the macOS examples natively:

   ```console
   $ cd lessons/04-first-program/apple-silicon/examples
   $ make
   $ ./exit42; echo $?
   42
   ```

4. Do the lesson's `exercises.md` as macOS programs, in
   `apple-silicon/work/`. macOS solutions are in `apple-silicon/solutions/`.

## Requirements

- Xcode command line tools: `xcode-select --install`
- `lldb` (included with the command line tools) for debugging.

## The differences, summarised

See [../docs/platform-differences.md](platform-differences.md). The big ones:

- Programs start at `_main`, and every C-visible symbol has a leading underscore.
- System calls use `x16` and `svc #0x80`, with BSD numbers, and are not a
  stable interface: from lesson 16 on we call libSystem instead.
- Addresses are loaded with `adrp x0, sym@PAGE` / `add x0, x0, sym@PAGEOFF`.
- `x18` is reserved by the OS.
- Variadic arguments (everything after the format string in `printf`) are
  passed on the stack, not in registers.
