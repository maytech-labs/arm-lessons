#!/usr/bin/env bash
# Build and run every program of one lesson in both flavors, then diff the
# results (exit status + first bytes of output). Run on macOS, from anywhere.
#
#   ./scripts/compare-tracks.sh 07            # stdin is "42"
#   ./scripts/compare-tracks.sh 11 "123"      # custom stdin
#
# Needs the arm-lessons Docker image (docker build -t arm-lessons .).
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
n="$1"; input="${2:-42}"
cd "$repo"
lesson=$(ls -d lessons/"$n"-*)
tmp=$(mktemp -d)

run='for d in examples solutions; do
  [ -f $d/Makefile ] || continue
  make -s -C $d >/dev/null || echo "BUILD FAILED: $d"
  for f in $d/*.s $d/*.c; do
    [ -e "$f" ] || continue; p=${f%.*}; [ -x $p ] || continue
    o=$(printf "%s\n" "$IN" | env -i PATH=/usr/bin:/bin HOME=/tmp LANG=C perl -e "alarm shift; exec @ARGV" 10 ./$p 2>/dev/null); rc=$?
    echo "$p rc=$rc | $(printf "%s" "$o" | head -c 160 | tr "\n" "~")"
  done
  make -s -C $d clean >/dev/null
done'

docker run --rm -e IN="$input" -v "$repo":/work -w "/work/$lesson/linux" arm-lessons bash -c "$run" >"$tmp/linux" 2>&1
[ -d "$lesson/apple-silicon" ] && (cd "$lesson/apple-silicon" && IN="$input" bash -c "$run") >"$tmp/mac" 2>&1

echo "== linux ($lesson)"; cat "$tmp/linux"
echo "== linux vs macOS"
diff "$tmp/linux" "$tmp/mac" && echo "identical"
find "$lesson" \( -name core -type f -delete \) -o \( -name '*.dSYM' -prune -exec rm -rf {} + \) 2>/dev/null
rm -rf "$tmp"
