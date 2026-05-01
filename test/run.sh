#!/usr/bin/env bash
# Build (if needed) and (re)launch the yterminal test container, then drop
# into an interactive shell. The repo is bind-mounted at /work, so any host
# edits to scripts/ or dotfiles/ are visible immediately — no image rebuild
# required for iteration.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="yterminal-test"
CONTAINER="yterminal-test"

cd "$REPO_ROOT"

echo "==> Building $IMAGE (cached unless test/Dockerfile changed)"
docker build -t "$IMAGE" "$REPO_ROOT/test"

echo "==> Recreating container '$CONTAINER' (clean slate)"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d \
  --name "$CONTAINER" \
  -v "$REPO_ROOT":/work \
  -w /work \
  "$IMAGE" >/dev/null

cat <<EOF

Container '$CONTAINER' is running.
  Repo bind-mounted at /work (host edits are live).

Inside the container:
  ./install.sh                     # run the full pipeline
  bash scripts/02-base-packages.sh # run a single step
  CODING_CLIS=all bash scripts/06-coding-clis.sh

Cleanup:
  docker rm -f $CONTAINER

EOF

# If we have a TTY, attach immediately.
if [[ -t 0 && -t 1 ]]; then
  exec docker exec -it "$CONTAINER" bash
fi
