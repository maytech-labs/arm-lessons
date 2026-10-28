#!/usr/bin/env bash
# Open a shell in the Linux AArch64 container with this repo mounted at /work.
# Builds the image on first use.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="arm-lessons"

if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker build --platform linux/arm64 -t "$image" "$repo_root"
fi

# --cap-add/--security-opt let gdb disable address randomization and trace processes.
exec docker run --rm -it --platform linux/arm64 \
  --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$repo_root":/work -w "/work/${1:-}" \
  "$image" bash
