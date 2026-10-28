#!/usr/bin/env bash
# Compare two run-all.sh outputs, ignoring programs listed in
# known-differences.txt. Exits non-zero if anything else differs.
#
#   ./scripts/diff-runs.sh linux.txt apple.txt
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
skip="$(grep -v '^#' "$here/known-differences.txt" | awk 'NF {print $1}')"
filter() { grep -v -F -f <(printf '%s\n' "$skip" | sed 's/$/ rc=/') "$1" | sort; }
if diff <(filter "$1") <(filter "$2"); then
  echo "Linux and macOS agree on $(filter "$1" | wc -l | tr -d ' ') programs."
else
  echo "Linux and macOS outputs differ (see above)." >&2
  exit 1
fi
