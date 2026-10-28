# Contributing

Thank you for helping. Most contributions to a course are corrections: a
wrong explanation, a confusing paragraph, a program that behaves differently
from its comment. Those are the most valuable kind.

## Reporting a problem

Open an issue with the **Erratum** template. Say which lesson, which flavor
(Linux, Apple Silicon, or the shared text), and what you expected versus what
you saw.

## Making a change

1. Read [docs/lesson-style-guide.md](docs/lesson-style-guide.md) (how lessons
   are written) and [AGENTS.md](AGENTS.md) (the repository rules, which apply
   to people too).
2. Keep the flavors in sync: a change to a program in `lessons/NN-*/linux/`
   needs the matching change in `lessons/NN-*/apple-silicon/`, and the other
   way round. `scripts/port-to-apple.py` and `scripts/port-libc-to-apple.py`
   do the mechanical part.
3. A lesson may only use what earlier lessons taught.
4. Check your change:

   ```console
   $ ./scripts/compare-tracks.sh NN     # on a Mac with Docker: both flavors, diffed
   $ python3 scripts/check-links.py     # every markdown link resolves
   ```

   CI runs the full check on every pull request: all programs on Linux and
   macOS, the comparison, the capstone tests, the links, and the book.
5. If a program's output must differ between platforms (it prints an address,
   a timing, or demonstrates a platform difference), add it to
   `scripts/known-differences.txt` with the reason.
6. Changes to conventions, structure, or scope need a decision record in
   [docs/decisions/](docs/decisions/).

## License

By contributing, you agree that your contribution is licensed under the
project's license, [REAL 1.0](LICENSE.md).
