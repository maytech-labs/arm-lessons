#!/usr/bin/env bash
# check.sh - run the capstone tests (lesson 31)
#
#   ./tests/check.sh PROJECT BINARY   test one program, e.g.
#                                     ./tests/check.sh wc work/wc/wc
#   ./tests/check.sh all DIR          test DIR/wc/wc, DIR/rpn/rpn, ... e.g.
#                                     ./tests/check.sh all solutions
#
# PROJECT is one of: wc rpn wordfreq life bf
#
# Each project directory (tests/wc, tests/rpn, ...) has a file called `cases`.
# Every line in it is one test:
#
#   name | arguments | stdin | expected exit status
#
# The program runs inside that directory, so file arguments are names of files
# next to `cases`. stdin is a file name, "-" for no input, or "!command" to
# feed the output of a shell command. The test passes when stdout matches
# NAME.out, stderr matches NAME.err (only checked if that file exists), and the
# exit status matches.
#
# Works with bash 3.2 (macOS) and later (Linux).

set -u

here="$(cd "$(dirname "$0")" && pwd)"
projects="wc rpn wordfreq life bf"
passed=0
failed=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

usage() {
    echo "usage: $0 PROJECT BINARY   (PROJECT: $projects)" >&2
    echo "       $0 all DIR" >&2
    exit 2
}

# Turn a possibly relative path into an absolute one.
abspath() {
    case "$1" in
        /*) echo "$1" ;;
        *)  echo "$PWD/$1" ;;
    esac
}

fail() {
    echo "FAIL $1"
    failed=$((failed + 1))
}

# run_project PROJECT BINARY
run_project() {
    local project="$1" bin="$2"
    local dir="$here/$project"
    local name args input status got

    if [ ! -f "$dir/cases" ]; then
        echo "unknown project: $project" >&2
        usage
    fi
    if [ ! -x "$bin" ]; then
        fail "$project (no executable at $bin - did you run make?)"
        return
    fi

    while IFS='|' read -r name args input status; do
        case "$name" in ''|'#'*) continue ;; esac

        # Run the program in the test directory. Arguments are split on
        # spaces; set -f stops the shell from expanding * or ?.
        set -f
        case "$input" in
            -)  (cd "$dir" && "$bin" $args </dev/null >"$tmp/out" 2>"$tmp/err") ;;
            !*) (cd "$dir" && sh -c "${input#!}" </dev/null | "$bin" $args >"$tmp/out" 2>"$tmp/err") ;;
            *)  (cd "$dir" && "$bin" $args <"$input" >"$tmp/out" 2>"$tmp/err") ;;
        esac
        got=$?
        set +f

        if ! cmp -s "$dir/$name.out" "$tmp/out"; then
            fail "$project/$name: stdout differs (expected < >  got)"
            diff "$dir/$name.out" "$tmp/out" | head -n 20
        elif [ -f "$dir/$name.err" ] && ! cmp -s "$dir/$name.err" "$tmp/err"; then
            fail "$project/$name: stderr differs (expected < >  got)"
            diff "$dir/$name.err" "$tmp/err" | head -n 20
        elif [ "$got" != "$status" ]; then
            fail "$project/$name: exit status $got, expected $status"
        else
            echo "PASS $project/$name"
            passed=$((passed + 1))
        fi
    done <"$dir/cases"
}

[ $# -eq 2 ] || usage

if [ "$1" = all ]; then
    base="$(abspath "$2")"
    for p in $projects; do
        run_project "$p" "$base/$p/$p"
    done
else
    run_project "$1" "$(abspath "$2")"
fi

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
