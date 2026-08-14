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

# REPO_URL is e.g. https://github.com/owner/repo — strip the host to get
# the "owner/repo" path the GitHub API wants.
REPO_PATH="${REPO_URL#https://github.com/}"
REPO_PATH="${REPO_PATH%/}"

# GitHub's runner *registration* tokens (as opposed to the long-lived GH_PAT)
# expire after ~1 hour, so one can't just be pasted into .env once and reused
# across restarts. Mint a fresh one from the PAT every time we need it instead
# — on register (start) and on deregister (stop), since that one can have
# expired too by the time the container is torn down.
mint_registration_token() {
  local token
  token=$(curl -sf -X POST \
    -H "Authorization: Bearer ${GH_PAT}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO_PATH}/actions/runners/registration-token" \
    | jq -r .token)

  if [ -z "${token}" ] || [ "${token}" = "null" ]; then
    echo "Failed to mint a registration token for ${REPO_PATH}." >&2
    echo "Check that GH_PAT is valid and has 'repo' scope (classic) or Administration:write (fine-grained), and that REPO_URL is correct." >&2
    exit 1
  fi

  echo "${token}"
}

./config.sh \
  --unattended \
  --url "${REPO_URL}" \
  --token "$(mint_registration_token)" \
  --name "${RUNNER_NAME:-docker-runner}" \
  --labels "${RUNNER_LABELS:-docker,self-hosted}" \
  --replace

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "$(mint_registration_token)" || true
}

trap cleanup EXIT

./run.sh
