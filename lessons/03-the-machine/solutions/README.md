# Lesson 03 solutions

Try each exercise before reading its answer. Your addresses may differ
slightly from the ones here.

## 03.1

1. 31: `x0` to `x30`. Each holds 64 bits.
2. The low 32 bits of `x7`. Same register, 32-bit name.
3. `0x0000000000000005`. Writing a `w` register sets the upper 32 bits to 0.
4. `0x9ABCDEF0`: the low 32 bits (the last eight hex digits).
5. 0. Writes to `xzr` are thrown away, and it always reads as zero.
6. `pc`, the program counter.
7. `x18`.

## 03.2

1. `0x2000`, `0x2001`, `0x2002`, `0x2003`. The next word starts at `0x2004`.
2. `0x2000` to `0x2007` (eight bytes).
3. `0x1FFF - 0x1000 + 1 = 0x1000` = 4096 bytes (4 KiB, one page).
4. `0x3000` holds `01` (little-endian: lowest address, low byte). The other
   seven, `0x3001` to `0x3007`, hold `00`.
5. 8 bytes (64 bits), because addresses are 64 bits.

## 03.3

1. Eight.
2. 8 × 4 = 32 bytes.
3. Something like `0x4000d4` and `0x4000f0`. The difference is `0x1c` = 28 =
   7 × 4: seven steps of 4 bytes from the first instruction to the last. (The
   last instruction itself takes the bytes up to `0x4000f3`, making 32.)
4. `d4000001`.

## 03.4

1. `mov x3, #42`: same as `mov x0, #42` (`d2800540`) but register 3 in the low
   five bits: **`d2800543`**.
2. `mov x0, #43`: 43 = `0x2B`, shifted left 5 bits = `0x560`:
   **`d2800560`**.
3. `mov w1, #42`: like `mov x1, #42` (`d2800541`) with bit 31 cleared, so the
   first hex digit goes from `d` (1101) to `5` (0101): **`52800541`**.

Program: [ex4.s](ex4.s).

## 03.5

The `.data` line shows `01020304 78563412 486921`: the four `.byte` values in
order, then the word `0x12345678` little-endian, then `H` `i` `!`.

1. `0d f0 fe ca` (shown as `0df0feca`).
2. `41 42 43`.
3. Reversed: `d2800ba8`, which is `mov x8, #0x5d`, that is `mov x8, #93`.

## 03.6

1. `encoding.o` is an `ELF 64-bit LSB relocatable` file; `encoding` is an
   `ELF 64-bit LSB executable`. "Relocatable" means its addresses are not
   final yet: the linker can still move it.
2. In the object file, addresses start at 0 because the assembler does not
   know where the code will go. The linker chose the final addresses
   (starting at `0x400078`).
3. `0x400078`, which is the address of `_start` in `nm encoding`. The linker
   used `_start` as the entry point.
4. `Permission denied` (exit status 126). An object file is not a program:
   it is not marked executable and has no entry point. It must be linked first.
5. Yes: it exits with status 42. The file is smaller than the one `make`
   built, because `make` adds debugging information (`-g`) and `gcc` asks the
   linker to record a build ID, but the instructions are identical.

## 03.7

Own instructions: 1, 3, 6, 8. Everything in registers and the program's own
memory is the program's business.

System call: 2 (the screen), 4 (the disk), 5 (only the kernel can end a
process and pass the status to the shell), 7 (the clock is hardware the
kernel owns).

## 03.8

| `pc` before | Instruction | `x0` after | `x1` after |
|-------------|-------------|------------|------------|
| `0x400100` | `mov x0, #5` | 5 | ? (whatever was there) |
| `0x400104` | `mov x1, #7` | 5 | 7 |
| `0x400108` | `mov x0, #9` | 9 | 7 |
| `0x40010c` | `mov w1, #3` | 9 | 3 (upper half cleared) |
| `0x400110` | `mov x8, #93` | 9 | 3 |
| `0x400114` | `svc #0` | | |

The exit status is **9**, the value of `x0` at the `svc`. The `svc` is at
`0x400114`.

(What is in `x1` before the program writes it? On Linux the kernel starts a
program with most registers set to 0, but do not rely on that: always set a
register before you use it.)

## 03.9

1. `d2800ba8`: the low five bits are `0x08` → register 8; the number field is
   `(0xd2800ba8 >> 5) & 0xFFFF = 0x5D` = 93; bit 31 is 1 → `x`. So
   `mov x8, #93`.
2. `52800fe1`: low five bits `00001` → register 1; number `0x7F` = 127; first
   hex digit `5` means bit 31 is 0 → `w`. So `mov w1, #127`.
3. `0xD2800000 | (0xFFFF << 5) | 30 = 0xD2800000 | 0x1FFFE0 | 0x1E =`
   **`d29ffffe`**.
4. `0xD2800000 | 0 | 5 =` **`d2800005`**.
5. The number field is 16 bits, so it holds at most 65,535 (`0xFFFF`), and
   70,000 needs 17 bits.
