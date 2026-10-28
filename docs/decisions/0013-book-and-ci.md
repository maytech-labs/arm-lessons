# 0013: Publish the lessons as a book, and test both flavors in CI

- **Status:** Accepted
- **Date:** 2026-10-28

## Context

Readers should be able to read the course as a website, and contributors need
to know that every program still builds and behaves the same on both
platforms.

## Decision

- **Book:** `scripts/build-book.py` generates an [mdBook](https://rust-lang.github.io/mdBook/)
  source tree in `build/book/` from the lessons and docs, in curriculum order,
  rewriting links: links between pages stay in the book; links to programs and
  other repo files go to GitHub. GitHub Actions builds it and deploys it to
  GitHub Pages on every push to `main`. The markdown in the repo remains the
  source of truth; nothing generated is committed.
- **CI** (`.github/workflows/ci.yml`), on every push and pull request:
  - **linux** on a GitHub-hosted arm64 Ubuntu runner: build every Linux
    program, run them all (`scripts/run-all.sh`), run the capstone tests.
  - **macos** on a GitHub-hosted Apple Silicon runner: the same for the macOS
    flavor.
  - **compare**: diff the two runs (`scripts/diff-runs.sh`), ignoring the
    programs listed in `scripts/known-differences.txt`.
  - **docs**: check every markdown link (`scripts/check-links.py`) and build
    the book.

## Alternatives considered

- **Committing the generated book** (`docs/` for GitHub Pages) - duplicates
  every page and drifts out of date.
- **Restructuring the repo to be the mdBook source directly** - forces a
  `SUMMARY.md` and mdBook conventions on everyone browsing the repo on GitHub.
- **Testing only on the maintainer's Mac** (Docker for Linux) - still possible
  with `scripts/compare-tracks.sh`, but not enforced for contributors.

## Consequences

Programs must stay deterministic (same output on both platforms) or be listed
in `known-differences.txt` with a reason. GitHub Pages must be enabled with
"GitHub Actions" as the source; for a private repository that requires a paid
GitHub plan.
