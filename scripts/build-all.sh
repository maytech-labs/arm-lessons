#!/usr/bin/env bash
# Build every examples/ and solutions/ directory of one flavor.
#
#   ./scripts/build-all.sh linux   # inside the container (scripts/linux-shell.sh)
#   ./scripts/build-all.sh apple   # on macOS
#
# Pass "clean" as a second argument to remove build output instead.
set -euo pipefail

flavor="${1:-}"
target="${2:-all}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"

case "$flavor" in
  linux) dir=linux ;;
  apple) dir=apple-silicon ;;
  *) echo "usage: $0 linux|apple [clean]" >&2; exit 2 ;;
esac

failed=0
for d in "$repo_root"/lessons/*/"$dir"/examples "$repo_root"/lessons/*/"$dir"/solutions; do
  [ -f "$d/Makefile" ] || continue
  if ! make -s -C "$d" "$target"; then
    echo "FAILED: ${d#"$repo_root"/}" >&2
    failed=1
  fi
done
exit "$failed"
