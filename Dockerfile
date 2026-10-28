# Linux AArch64 environment for the main lesson track.
# On Apple Silicon this runs natively (no emulation): the container is arm64 Linux.
#
#   docker build -t arm-lessons .
#   ./scripts/linux-shell.sh
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential gdb binutils make file strace less vim-tiny xxd ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
CMD ["bash"]
