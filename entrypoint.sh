#!/bin/bash
set -e

cd /home/runner

# _work is a mounted volume (see docker-compose.yml) and Docker doesn't
# guarantee it's owned by the runner user on every start (e.g. a fresh
# named volume can come up root-owned) — without this, actions that write
# into _work/_tool (like subosito/flutter-action's tool cache) fail with
# "Permission denied" / UnauthorizedAccessException.
sudo mkdir -p _work
sudo chown -R "$(id -u):$(id -g)" _work

./config.sh \
  --unattended \
  --url "${REPO_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${RUNNER_NAME:-docker-runner}" \
  --labels "${RUNNER_LABELS:-docker,self-hosted}" \
  --replace

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "${RUNNER_TOKEN}" || true
}

trap cleanup EXIT

./run.sh