#!/usr/bin/env bash
# Build every examples/ and solutions/ directory for one track.
#
#   ./scripts/build-all.sh linux   # run inside the container (scripts/linux-shell.sh)
#   ./scripts/build-all.sh apple   # run on macOS
#
# Pass "clean" as a second argument to remove build output instead.
set -euo pipefail

track="${1:-}"
target="${2:-all}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

case "$track" in
  linux) base="$repo_root/lessons" ;;
  apple) base="$repo_root/apple-silicon" ;;
  *) echo "usage: $0 linux|apple [clean]" >&2; exit 2 ;;
esac

failed=0
for dir in "$base"/*/examples "$base"/*/solutions; do
  [ -f "$dir/Makefile" ] || continue
  if ! make -s -C "$dir" "$target"; then
    echo "FAILED: ${dir#"$repo_root"/}" >&2
    failed=1
  fi
done
exit "$failed"
