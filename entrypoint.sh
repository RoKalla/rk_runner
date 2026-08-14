#!/bin/bash
set -e

cd /home/runner

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