#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

# Script to find the latest Zed nightly commit with a successful release_nightly workflow.

set -euo pipefail

REPO="zed-industries/zed"
WORKFLOW_FILE="release_nightly.yml"
TOKEN_FILE="/run/agenix/github-ro-token"

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

# Query the workflow's runs directly, filtered to successful pushes, newest first.
echo "Fetching latest successful $WORKFLOW_FILE run for $REPO..."
RUNS_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?status=success&event=push&per_page=1")

if ! echo "$RUNS_RESPONSE" | jq -e '.workflow_runs[0].head_sha' >/dev/null 2>&1; then
    echo "Error: Unexpected API response when fetching workflow runs. Raw response:"
    echo "$RUNS_RESPONSE"
    exit 2
fi

LATEST_SUCCESSFUL_COMMIT=$(echo "$RUNS_RESPONSE" | jq -r '.workflow_runs[0].head_sha')

if [[ -n "$LATEST_SUCCESSFUL_COMMIT" && "$LATEST_SUCCESSFUL_COMMIT" != "null" ]]; then
    echo "Latest successful commit for $WORKFLOW_FILE workflow: $LATEST_SUCCESSFUL_COMMIT"
else
    echo "No successful $WORKFLOW_FILE workflow run found."
    exit 1
fi
