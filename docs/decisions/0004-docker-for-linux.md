# 0004: Run the Linux track in an arm64 Docker container on the Mac

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

The main track targets Linux AArch64, but the learner's machine is a Mac.

## Decision

Provide a `Dockerfile` (Debian bookworm with `build-essential`, `gdb`, `strace`)
and `scripts/linux-shell.sh`, which mounts the repo at `/work`. On Apple Silicon
an arm64 container runs natively, so programs run at full speed and behave
exactly as on real Linux hardware.

## Alternatives considered

- **A full VM (UTM, Lima)** - heavier, more setup, no benefit for this course.
- **QEMU user-mode emulation** - unnecessary when the hardware is already ARM64.
- **Cross-compiling on macOS** - still needs Linux to run the result.

## Consequences

Docker Desktop (or an equivalent such as OrbStack or Colima) is a prerequisite.
The container is started with `SYS_PTRACE` so `gdb` works.
