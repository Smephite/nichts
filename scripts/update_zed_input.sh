#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix git

# Update the `zed` flake input in flake.nix to the latest Zed commit with a
# successful release_nightly workflow run, then refresh flake.lock.

set -euo pipefail

REPO="zed-industries/zed"
WORKFLOW_FILE="release_nightly.yml"
TOKEN_FILE="/run/agenix/github-ro-token"

REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
FLAKE_NIX="$REPO_ROOT/flake.nix"

if [[ ! -f "$FLAKE_NIX" ]]; then
    echo "flake.nix not found at $FLAKE_NIX"
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

# Idempotent skip when flake.nix already pins this exact commit.
if grep -qE "zed\.url *= *\"github:zed-industries/zed/$SHA\"" "$FLAKE_NIX"; then
    echo "flake.nix already pins zed to $SHA; nothing to do."
    exit 0
fi

# Rewrite zed.url, whether it currently has a rev suffix or not.
sed -i -E "s|(zed\.url *= *\"github:zed-industries/zed)(/[A-Za-z0-9._-]+)?\";|\1/$SHA\";|" "$FLAKE_NIX"

if ! grep -qE "zed\.url *= *\"github:zed-industries/zed/$SHA\"" "$FLAKE_NIX"; then
    echo "Error: failed to rewrite zed.url in $FLAKE_NIX"
    exit 3
fi

echo "Updated $FLAKE_NIX zed input to $SHA"

echo "Refreshing flake.lock for the zed input..."
( cd "$REPO_ROOT" && nix flake update zed )

echo "Done."
