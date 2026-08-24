#!/bin/bash
#
# Runs the Debian 13 suite in a throwaway container.
#
# The repo is mounted read-only, so the tests exercise the working tree
# without being able to change it, and the container is discarded after.
#
# Usage:
#   ./test/debian_13/run.sh                 Run everything
#   ./test/debian_13/run.sh --filter NAME   Run the tests matching NAME
#   ./test/debian_13/run.sh --shell         Open a shell in the container

set -e

SH_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_ROOT="$(cd "$SH_HERE/../.." && pwd)"

OS="$(basename "$SH_HERE")"
IMAGE="prelude-test-${OS}"

command -v docker > /dev/null || {
  echo "docker is required to run the tests" >&2
  exit 1
}

docker build --quiet --tag "$IMAGE" "$SH_HERE" > /dev/null

if [ "${1:-}" = "--shell" ]; then
  exec docker run --rm -it -v "$SH_ROOT:/repo:ro" "$IMAGE" bash
fi

exec docker run --rm -v "$SH_ROOT:/repo:ro" "$IMAGE" \
  bats --print-output-on-failure "$@" "/repo/test/${OS}/specs"
