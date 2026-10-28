#!/usr/bin/env bash
# Run every built program of one flavor and print one line per program:
#
#   NN-slug/examples/prog rc=STATUS | first 160 bytes of stdout (newlines as ~)
#
# Lines are the same for both flavors when the programs behave the same, so
# CI diffs the Linux and macOS outputs (see scripts/known-differences.txt).
# Every program gets "42" on stdin, 10 seconds, and an empty environment
# (just PATH, HOME=/tmp, LANG=C). Build first with
# scripts/build-all.sh.
#
#   ./scripts/run-all.sh linux > linux.txt
#   ./scripts/run-all.sh apple > apple.txt
set -uo pipefail

flavor="${1:-}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
case "$flavor" in
  linux) dir=linux ;;
  apple) dir=apple-silicon ;;
  *) echo "usage: $0 linux|apple" >&2; exit 2 ;;
esac

for d in "$repo_root"/lessons/*/"$dir"/examples "$repo_root"/lessons/*/"$dir"/solutions; do
  [ -d "$d" ] || continue
  lesson="$(basename "$(dirname "$(dirname "$d")")")"
  for p in "$d"/*; do
    [ -f "$p" ] && [ -x "$p" ] || continue
    case "$(basename "$p")" in *.*|Makefile) continue ;; esac   # programs have no extension
    name="$lesson/$(basename "$d")/$(basename "$p")"
    # A clean, fixed environment: deterministic output, and examples that
    # print the environment (lesson 25) never show the caller's secrets.
    out="$(cd "$d" && printf '42\n' | env -i PATH=/usr/bin:/bin HOME=/tmp LANG=C \
             perl -e 'alarm shift; exec @ARGV' 10 "./$(basename "$p")" 2>/dev/null)"
    rc=$?
    echo "$name rc=$rc | $(printf '%s' "$out" | head -c 160 | tr '\n' '~')"
  done
done
