#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix git

# Update the `zed` flake input in flake.lock to the latest Zed commit
# with a successful release_nightly workflow run. flake.nix is left
# untouched; the pin lives in flake.lock via --override-input.

set -euo pipefail

REPO="zed-industries/zed"
WORKFLOW_FILE="release_nightly.yml"
TOKEN_FILE="/run/agenix/github-ro-token"

REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
FLAKE_LOCK="$REPO_ROOT/flake.lock"

if [[ ! -f "$FLAKE_LOCK" ]]; then
    echo "flake.lock not found at $FLAKE_LOCK"
    exit 1
fi

if [[ ! -f "$TOKEN_FILE" ]]; then
    echo "GitHub token file not found at $TOKEN_FILE"
    exit 1
fi

GITHUB_TOKEN=$(grep '^access-tokens *= *github.com=' "$TOKEN_FILE" | sed 's/.*=//')
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Could not extract GitHub token from $TOKEN_FILE"
    exit 1
fi

echo "Using GitHub token: ${GITHUB_TOKEN:0:4}... (truncated)"

echo "Fetching latest successful $WORKFLOW_FILE run for $REPO..."
RUNS_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?status=success&event=push&per_page=1")

if ! echo "$RUNS_RESPONSE" | jq -e '.workflow_runs[0].head_sha' >/dev/null 2>&1; then
    echo "Error: Unexpected API response when fetching workflow runs. Raw response:"
    echo "$RUNS_RESPONSE"
    exit 2
fi

SHA=$(echo "$RUNS_RESPONSE" | jq -r '.workflow_runs[0].head_sha')
if [[ -z "$SHA" || "$SHA" == "null" ]]; then
    echo "No successful $WORKFLOW_FILE workflow run found."
    exit 1
fi

echo "Latest successful zed nightly commit: $SHA"

CURRENT_SHA=$(jq -r '.nodes.zed.locked.rev // empty' "$FLAKE_LOCK")
if [[ "$CURRENT_SHA" == "$SHA" ]]; then
    echo "flake.lock already pins zed to $SHA; nothing to do."
    exit 0
fi

echo "Updating flake.lock zed input to $SHA..."
( cd "$REPO_ROOT" && nix flake update zed --override-input zed "github:zed-industries/zed/$SHA" )

NEW_SHA=$(jq -r '.nodes.zed.locked.rev // empty' "$FLAKE_LOCK")
if [[ "$NEW_SHA" != "$SHA" ]]; then
    echo "Error: flake.lock zed rev is '$NEW_SHA', expected '$SHA'"
    exit 3
fi

echo "Done."
