# AArch64 cheat sheet

Everything here is taught in the lessons; this page is for looking things up.
`Xd` = destination, `Xn`/`Xm` = sources, `#imm` = immediate constant.

## Registers

| Register | 32-bit view | Role (AAPCS64) | Saved by |
|----------|-------------|----------------|----------|
| `x0`-`x7` | `w0`-`w7` | Arguments and return values (`x0`, `x1`) | caller |
| `x8` | `w8` | Indirect result address (large struct return); Linux syscall number | caller |
| `x9`-`x15` | `w9`-`w15` | Temporaries | caller |
| `x16`, `x17` | `w16`, `w17` | Intra-procedure-call scratch (`ip0`, `ip1`); macOS syscall number in `x16` | caller |
| `x18` | `w18` | Platform register: **never use** | - |
| `x19`-`x28` | `w19`-`w28` | Long-lived values | **callee** |
| `x29` (`fp`) | | Frame pointer | **callee** |
| `x30` (`lr`) | | Link register: return address | **callee** (save before `bl`) |
| `sp` | `wsp` | Stack pointer, always 16-byte aligned | **callee** |
| `xzr` | `wzr` | Reads as zero, writes are discarded | - |
| `pc` | | Program counter: not directly writable | - |
| `v0`-`v7` | `d0`-`d7`, `s0`-`s7` | FP arguments and return values | caller |
| `v8`-`v15` | `d8`-`d15` | Low 64 bits callee-saved | **callee** |
| `v16`-`v31` | | FP temporaries | caller |

Writing a `w` register zeroes the upper 32 bits of the `x` register.

## Moving data

| Instruction | Effect |
|-------------|--------|
| `mov Xd, Xn` | `Xd = Xn` |
| `mov Xd, #imm` | `Xd = imm` (assembler picks an encoding) |
| `movz Xd, #imm16, lsl #s` | `Xd = imm16 << s` (s = 0, 16, 32, 48) |
| `movk Xd, #imm16, lsl #s` | replace 16 bits of `Xd` at position s, keep the rest |
| `mvn Xd, Xn` | `Xd = ~Xn` |
| `adr Xd, label` | `Xd = address of label` (within +/-1 MiB) |
| `adrp Xd, label` | `Xd = address of label's 4 KiB page` |

## Arithmetic

| Instruction | Effect |
|-------------|--------|
| `add Xd, Xn, Xm` / `#imm` | `Xd = Xn + Xm` |
| `sub Xd, Xn, Xm` / `#imm` | `Xd = Xn - Xm` |
| `adds` / `subs` | same, and set flags |
| `adc` / `sbc` | add/subtract with carry |
| `neg Xd, Xn` | `Xd = -Xn` |
| `mul Xd, Xn, Xm` | `Xd = Xn * Xm` (low 64 bits) |
| `madd Xd, Xn, Xm, Xa` | `Xd = Xa + Xn * Xm` |
| `msub Xd, Xn, Xm, Xa` | `Xd = Xa - Xn * Xm` |
| `umulh` / `smulh` | high 64 bits of a 128-bit product |
| `udiv` / `sdiv Xd, Xn, Xm` | `Xd = Xn / Xm` (truncates; divide by zero gives 0, no trap) |

Remainder: `udiv q, a, b` then `msub r, q, b, a` gives `r = a - q*b`.

## Bitwise and shifts

| Instruction | Effect |
|-------------|--------|
| `and`, `orr`, `eor` | `&`, `\|`, `^` |
| `bic Xd, Xn, Xm` | `Xd = Xn & ~Xm` |
| `orn`, `eon` | `Xn \| ~Xm`, `Xn ^ ~Xm` |
| `lsl`, `lsr`, `asr`, `ror` | shift left, logical right, arithmetic right, rotate |
| `ubfx Xd, Xn, #lsb, #w` | extract unsigned bit field |
| `sbfx` | extract signed bit field |
| `bfi Xd, Xn, #lsb, #w` | insert bit field |
| `clz`, `rbit`, `rev` | count leading zeros, reverse bits, reverse bytes |
| `sxtb`/`sxth`/`sxtw`, `uxtb`/`uxth` | sign/zero extend byte/half/word |

Most data-processing instructions accept a shifted second operand:
`add x0, x1, x2, lsl #3` is `x0 = x1 + (x2 << 3)`.

## Flags and conditions

`cmp Xn, Xm` computes `Xn - Xm` and sets `N Z C V`. `tst` does `and`, `cmn` does `add`.

| Cond | Meaning | Signed? | C after `cmp a, b` |
|------|---------|---------|--------------------|
| `eq` | Z=1 | either | `a == b` |
| `ne` | Z=0 | either | `a != b` |
| `lt` | N!=V | signed | `a < b` |
| `le` | Z=1 or N!=V | signed | `a <= b` |
| `gt` | Z=0 and N=V | signed | `a > b` |
| `ge` | N=V | signed | `a >= b` |
| `lo` (`cc`) | C=0 | unsigned | `a < b` |
| `ls` | C=0 or Z=1 | unsigned | `a <= b` |
| `hi` | C=1 and Z=0 | unsigned | `a > b` |
| `hs` (`cs`) | C=1 | unsigned | `a >= b` |
| `mi` / `pl` | N=1 / N=0 | | negative / non-negative |
| `vs` / `vc` | V=1 / V=0 | | signed overflow / none |

## Branches and selects

| Instruction | Effect |
|-------------|--------|
| `b label` | jump |
| `b.cond label` | jump if condition |
| `cbz` / `cbnz Xn, label` | jump if `Xn == 0` / `!= 0` |
| `tbz` / `tbnz Xn, #bit, label` | jump if bit is 0 / 1 |
| `bl label` | call: `x30 = return address`, jump |
| `blr Xn` | call the address in `Xn` |
| `br Xn` | jump to the address in `Xn` |
| `ret` | return to `x30` |
| `csel Xd, Xn, Xm, cond` | `Xd = cond ? Xn : Xm` |
| `cset Xd, cond` | `Xd = cond ? 1 : 0` |
| `csinc`, `csinv`, `csneg`, `cinc`, `cneg` | conditional increment / invert / negate |

## Memory

| Instruction | Size | Extension |
|-------------|------|-----------|
| `ldr Xt` / `str Xt` | 8 bytes | |
| `ldr Wt` / `str Wt` | 4 bytes | zero-extend |
| `ldrsw Xt` | 4 bytes | sign-extend |
| `ldrh` / `strh` | 2 bytes | zero-extend |
| `ldrsh` | 2 bytes | sign-extend |
| `ldrb` / `strb` | 1 byte | zero-extend |
| `ldrsb` | 1 byte | sign-extend |
| `ldp` / `stp` | two registers | |

| Addressing mode | Address used | Base register after |
|-----------------|--------------|---------------------|
| `[Xn]` | `Xn` | unchanged |
| `[Xn, #imm]` | `Xn + imm` | unchanged |
| `[Xn, Xm]` | `Xn + Xm` | unchanged |
| `[Xn, Xm, lsl #s]` | `Xn + (Xm << s)`, s = log2(size) | unchanged |
| `[Xn, Wm, sxtw #s]` | `Xn + (sign-extended Wm << s)` | unchanged |
| `[Xn, #imm]!` | `Xn + imm` (pre-index) | `Xn + imm` |
| `[Xn], #imm` | `Xn` (post-index) | `Xn + imm` |

## Function template

```asm
func:
    stp x29, x30, [sp, #-32]!   // save frame pointer and return address, reserve 32 bytes
    mov x29, sp                 // set up frame pointer
    str x19, [sp, #16]          // save a callee-saved register we will use
    // ... body ...
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
```

## Floating point

| Instruction | Effect |
|-------------|--------|
| `fmov Dd, Dn` / `#imm` / `Xn` | move. Immediates are only ±(16..31)/16 × 2^(-3..4): `1.0`, `0.5`, `2.5` work; `0.0`, `0.1`, `32.0` do not. Zero: `fmov d0, xzr` |
| `fadd`, `fsub`, `fmul`, `fdiv` | arithmetic |
| `fsqrt`, `fabs`, `fneg` | |
| `fmadd Dd, Dn, Dm, Da` | `Dd = Da + Dn * Dm` |
| `fmsub Dd, Dn, Dm, Da` | `Dd = Da - Dn * Dm` |
| `fcsel Dd, Dn, Dm, cond` | `Dd = cond ? Dn : Dm` |
| `fcmp Dn, Dm` | compare, sets flags (use `mi`, `ls`, `gt`, `ge`, `eq`, `vs` for unordered) |
| `scvtf Dd, Xn` / `ucvtf` | integer to float |
| `fcvtzs Xd, Dn` / `fcvtzu` | float to integer, truncating (C cast) |
| `fcvt Dd, Sn` / `fcvt Sd, Dn` | float to/from double |
| `ldr Dt` / `str Dt` | load/store 8-byte double (`St` for 4-byte float) |

## System calls

| | Linux | macOS |
|-|-------|-------|
| Number in | `x8` | `x16` |
| Instruction | `svc #0` | `svc #0x80` |
| `exit(code)` | 93 | 1 |
| `read(fd, buf, n)` | 63 | 3 |
| `write(fd, buf, n)` | 64 | 4 |
| `openat` / `open` | 56 (`openat`) | 5 (`open`) |
| `close(fd)` | 57 | 6 |
