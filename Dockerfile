# Linux AArch64 environment for the main lesson track.
# On Apple Silicon this runs natively (no emulation): the container is arm64 Linux.
#
#   docker build -t arm-lessons .
#   ./scripts/linux-shell.sh
# Pinned by digest so the toolchain (gcc, binutils, gdb) only changes when we
# choose to update it: docker buildx imagetools inspect debian:bookworm-slim
FROM debian:bookworm-slim@sha256:99c0b25c46d0214d5a2091092e7908907dcaecd6a962cde0ac700acee222b6f3

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential gdb binutils make file strace less vim-tiny xxd ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
CMD ["bash"]
