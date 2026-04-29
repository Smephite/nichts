#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age jq
set -euo pipefail

PREFIX="managed-"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${1:-"$SCRIPT_DIR/user"}"
KEY_DIRS=("$KEY_DIR" "$SCRIPT_DIR/master")

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  AGE_FILE="$SCRIPT_DIR/../github-ssh.age"
  if [[ -f "$AGE_FILE" ]] && command -v age &>/dev/null; then
    echo "GITHUB_TOKEN not set, attempting to decrypt github-ssh.age..." >&2
    GITHUB_TOKEN="$(age -d -i ~/.ssh/id_ed25519 "$AGE_FILE")" || {
      echo "Error: Failed to decrypt $AGE_FILE" >&2
      exit 1
    }
    export GITHUB_TOKEN
  else
    echo "Error: GITHUB_TOKEN env var is not set and could not decrypt $AGE_FILE" >&2
    echo "  Either set GITHUB_TOKEN (scopes: admin:public_key, admin:ssh_signing_key)" >&2
    echo "  or ensure github-admin.age exists and age is installed." >&2
    exit 1
  fi
fi

for cmd in curl jq age; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not found" >&2
    exit 1
  fi
done

if [[ ! -d "$KEY_DIR" ]]; then
  echo "Error: Key directory not found: $KEY_DIR" >&2
  exit 1
fi

API="https://api.github.com"
AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
ACCEPT_HEADER="Accept: application/vnd.github+json"

gh_get() {
  local endpoint="$1"
  local page=1
  local results="[]"
  while true; do
    local response
    response=$(curl -sf -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "$API$endpoint?per_page=100&page=$page")
    local count
    count=$(echo "$response" | jq 'length')
    results=$(echo "$results" "$response" | jq -s '.[0] + .[1]')
    if [[ "$count" -lt 100 ]]; then
      break
    fi
    page=$((page + 1))
  done
  echo "$results"
}

gh_post() {
  local endpoint="$1"
  local data="$2"
  local response http_code
  response=$(curl -s -w "\n%{http_code}" -X POST -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" -H "Content-Type: application/json" -d "$data" "$API$endpoint")
  http_code=$(echo "$response" | tail -1)
  response=$(echo "$response" | sed '$d')
  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$response"
  else
    echo "  ERROR (HTTP $http_code): $(echo "$response" | jq -r '.message // .errors[0].message // "unknown error"')" >&2
    return 1
  fi
}

gh_delete() {
  local endpoint="$1"
  curl -sf -X DELETE -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" "$API$endpoint"
}

# Extract key material (type + base64) from a full public key line, stripping comments
key_material() {
  echo "$1" | awk '{print $1, $2}'
}

# Collect local keys: map of "key_material" -> "title"
declare -A local_keys=()
declare -A local_key_full=()

pub_files=()
for dir in "${KEY_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    for f in "$dir"/*.pub; do
      [[ -e "$f" ]] && pub_files+=("$f")
    done
  fi
done

if [[ "${#pub_files[@]}" -eq 0 ]]; then
  echo "No .pub files found in: ${KEY_DIRS[*]}"
  exit 0
fi

for pub_file in "${pub_files[@]}"; do
  hostname="$(basename "$pub_file" .pub)"
  title="${PREFIX}${hostname}"
  content="$(cat "$pub_file")"
  km="$(key_material "$content")"
  local_keys["$km"]="$title"
  local_key_full["$km"]="$content"
done

echo "Found ${#local_keys[@]} local .pub file(s) in $KEY_DIR"
echo

# Fetch existing GitHub keys
echo "Fetching existing GitHub authentication keys..."
remote_auth_keys=$(gh_get "/user/keys")

echo "Fetching existing GitHub signing keys..."
remote_signing_keys=$(gh_get "/user/ssh_signing_keys")

# Build maps of ALL remote keys (to detect duplicates under different names)
# and separately track only managed keys (for removal logic)
declare -A all_remote_auth_titles=()
declare -A all_remote_auth_ids=()
declare -A all_remote_signing_titles=()
declare -A all_remote_signing_ids=()
declare -A remote_auth_ids=()
declare -A remote_auth_titles=()
declare -A remote_signing_ids=()
declare -A remote_signing_titles=()

while IFS=$'\t' read -r id title key; do
  [[ -z "$id" ]] && continue
  km="$(key_material "$key")"
  all_remote_auth_titles["$km"]="$title"
  all_remote_auth_ids["$km"]="$id"
  if [[ "$title" == "${PREFIX}"* ]]; then
    remote_auth_ids["$km"]="$id"
    remote_auth_titles["$km"]="$title"
  fi
done < <(echo "$remote_auth_keys" | jq -r '.[] | [.id, .title, .key] | @tsv')

while IFS=$'\t' read -r id title key; do
  [[ -z "$id" ]] && continue
  km="$(key_material "$key")"
  all_remote_signing_titles["$km"]="$title"
  all_remote_signing_ids["$km"]="$id"
  if [[ "$title" == "${PREFIX}"* ]]; then
    remote_signing_ids["$km"]="$id"
    remote_signing_titles["$km"]="$title"
  fi
done < <(echo "$remote_signing_keys" | jq -r '.[] | [.id, .title, .key] | @tsv')

echo "Found ${#remote_auth_ids[@]} managed remote auth key(s), ${#remote_signing_ids[@]} managed remote signing key(s)"
echo

# Add missing keys
for km in "${!local_keys[@]}"; do
  title="${local_keys["$km"]}"
  full_key="${local_key_full["$km"]}"
  key_json=$(jq -n --arg title "$title" --arg key "$full_key" '{title: $title, key: $key}')

  if [[ -n "${remote_auth_ids["$km"]+x}" ]]; then
    echo "Unchanged authentication key: $title"
  elif [[ -n "${all_remote_auth_titles["$km"]+x}" ]]; then
    old_title="${all_remote_auth_titles["$km"]}"
    old_id="${all_remote_auth_ids["$km"]}"
    echo "Renaming authentication key: '$old_title' -> '$title' (delete+re-add)"
    gh_delete "/user/keys/$old_id"
    gh_post "/user/keys" "$key_json" >/dev/null || true
  else
    echo "Adding authentication key: $title"
    gh_post "/user/keys" "$key_json" >/dev/null || true
  fi

  if [[ -n "${remote_signing_ids["$km"]+x}" ]]; then
    echo "Unchanged signing key: $title"
  elif [[ -n "${all_remote_signing_titles["$km"]+x}" ]]; then
    old_title="${all_remote_signing_titles["$km"]}"
    old_id="${all_remote_signing_ids["$km"]}"
    echo "Renaming signing key: '$old_title' -> '$title' (delete+re-add)"
    gh_delete "/user/ssh_signing_keys/$old_id"
    gh_post "/user/ssh_signing_keys" "$key_json" >/dev/null || true
  else
    echo "Adding signing key: $title"
    gh_post "/user/ssh_signing_keys" "$key_json" >/dev/null || true
  fi
done

echo

# Remove managed remote keys not present locally
for km in "${!remote_auth_ids[@]}"; do
  if [[ -z "${local_keys["$km"]+x}" ]]; then
    id="${remote_auth_ids["$km"]}"
    title="${remote_auth_titles["$km"]}"
    echo "Removing authentication key: $title (id=$id)"
    gh_delete "/user/keys/$id"
  fi
done

for km in "${!remote_signing_ids[@]}"; do
  if [[ -z "${local_keys["$km"]+x}" ]]; then
    id="${remote_signing_ids["$km"]}"
    title="${remote_signing_titles["$km"]}"
    echo "Removing signing key: $title (id=$id)"
    gh_delete "/user/ssh_signing_keys/$id"
  fi
done

echo
echo "Done."
