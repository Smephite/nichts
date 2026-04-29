#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age jq
set -euo pipefail

PREFIX="managed-"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${1:-"$SCRIPT_DIR/user"}"
KEY_DIRS=("$KEY_DIR" "$SCRIPT_DIR/master")

# Read GitLab tokens from agenix file (format: <host>:<token> per line)
GITLAB_TOKEN_FILE="$SCRIPT_DIR/../gitlab-ssh.age"
declare -A GITLAB_TOKENS=()

if [[ -f "$GITLAB_TOKEN_FILE" ]] && command -v age &>/dev/null; then
  while IFS=: read -r host token; do
    [[ -z "$host" || -z "$token" ]] && continue
    GITLAB_TOKENS["$host"]="$token"
  done < <(age -d -i ~/.ssh/id_ed25519 "$GITLAB_TOKEN_FILE")
else
  echo "Error: GitLab token file $GITLAB_TOKEN_FILE not found or age not installed" >&2
  exit 1
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

# GitLab API helpers
# Usage: gl_get <host> <endpoint>
gl_get() {
  local host="$1"
  local endpoint="$2"
  local token="${GITLAB_TOKENS[$host]}"
  curl -sf -H "PRIVATE-TOKEN: $token" "https://$host/api/v4$endpoint"
}

gl_post() {
  local host="$1"
  local endpoint="$2"
  local data="$3"
  local token="${GITLAB_TOKENS[$host]}"
  curl -sf -X POST -H "PRIVATE-TOKEN: $token" -H "Content-Type: application/json" -d "$data" "https://$host/api/v4$endpoint"
}

gl_delete() {
  local host="$1"
  local endpoint="$2"
  local token="${GITLAB_TOKENS[$host]}"
  curl -sf -X DELETE -H "PRIVATE-TOKEN: $token" "https://$host/api/v4$endpoint"
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

for host in "${!GITLAB_TOKENS[@]}"; do
  echo "Processing GitLab instance: $host"

  # Fetch existing SSH keys
  remote_keys=$(gl_get "$host" "/user/keys")

  # Build maps of ALL remote keys and managed keys
  declare -A all_remote_titles=()
  declare -A all_remote_ids=()
  declare -A remote_ids=()
  declare -A remote_titles=()

  while IFS=$'\t' read -r id title key; do
    [[ -z "$id" ]] && continue
    km="$(key_material "$key")"
    all_remote_titles["$km"]="$title"
    all_remote_ids["$km"]="$id"
    if [[ "$title" == "${PREFIX}"* ]]; then
      remote_ids["$km"]="$id"
      remote_titles["$km"]="$title"
    fi
  done < <(echo "$remote_keys" | jq -r '.[] | [.id, .title, .key] | @tsv')

  echo "Found ${#remote_ids[@]} managed remote key(s) on $host"
  echo

  # Add missing keys
  for km in "${!local_keys[@]}"; do
    title="${local_keys["$km"]}"
    full_key="${local_key_full["$km"]}"
    key_json=$(jq -n --arg title "$title" --arg key "$full_key" '{title: $title, key: $key}')

    if [[ -n "${remote_ids["$km"]+x}" ]]; then
      echo "Unchanged key: $title"
    elif [[ -n "${all_remote_titles["$km"]+x}" ]]; then
      old_title="${all_remote_titles["$km"]}"
      old_id="${all_remote_ids["$km"]}"
      echo "Renaming key: '$old_title' -> '$title' (delete+re-add)"
      gl_delete "$host" "/user/keys/$old_id"
      gl_post "$host" "/user/keys" "$key_json" >/dev/null || true
    else
      echo "Adding key: $title"
      gl_post "$host" "/user/keys" "$key_json" >/dev/null || true
    fi
  done

  echo

  # Remove managed remote keys not present locally
  for km in "${!remote_ids[@]}"; do
    if [[ -z "${local_keys["$km"]+x}" ]]; then
      id="${remote_ids["$km"]}"
      title="${remote_titles["$km"]}"
      echo "Removing key: $title (id=$id)"
      gl_delete "$host" "/user/keys/$id"
    fi
  done

  echo

done

echo "Done."
