#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age jq
set -euo pipefail

PREFIX="managed-"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${1:-"$SCRIPT_DIR/user"}"
KEY_DIRS=("$KEY_DIR" "$SCRIPT_DIR/master")

# Read Forgejo/Gitea tokens from agenix file (format: <host>:<token> per line)
# <host> can include a port (e.g. host:31415) or protocol (e.g. http://host)
FORGEJO_TOKEN_FILE="$SCRIPT_DIR/../forgejo-ssh.age"
declare -A FORGEJO_TOKENS=()

if [[ -f "$FORGEJO_TOKEN_FILE" ]] && command -v age &>/dev/null; then
  while IFS=: read -r -a parts; do
    [[ "${#parts[@]}" -lt 2 ]] && continue
    token="${parts[-1]}"
    # Everything before the last colon is the host/base_url
    host=$(IFS=:; echo "${parts[*]:0:${#parts[@]}-1}")
    [[ -z "$host" || -z "$token" ]] && continue
    FORGEJO_TOKENS["$host"]="$token"
  done < <(age -d -i ~/.ssh/id_ed25519 "$FORGEJO_TOKEN_FILE")
else
  # Fallback to single token if only CODEBERG_TOKEN is set
  if [[ -n "${CODEBERG_TOKEN:-}" ]]; then
    FORGEJO_TOKENS["codeberg.org"]="$CODEBERG_TOKEN"
  else
    echo "Error: Forgejo token file $FORGEJO_TOKEN_FILE not found or age not installed" >&2
    echo "  Ensure forgejo-ssh.age exists and age is installed." >&2
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

# Forgejo API helpers
# Usage: fj_get <host_or_url> <endpoint>
fj_get() {
  local target="$1"
  local endpoint="$2"
  local token="${FORGEJO_TOKENS[$target]:-}"

  if [[ -z "$token" ]]; then
    echo "  Error: No token found for $target" >&2
    return 1
  fi

  local base_url="$target"
  if [[ ! "$base_url" =~ ^https?:// ]]; then
    base_url="https://$base_url"
  fi
  base_url="${base_url%/}"

  # For specific items (containing an ID), don't paginate
  if [[ "$endpoint" =~ /[0-9]+$ ]]; then
    curl -sf -H "Authorization: token $token" -H "Accept: application/json" "$base_url/api/v1$endpoint"
    return
  fi

  local page=1
  local results="[]"
  while true; do
    local response
    # Try with Forgejo-specific header as well
    response=$(curl -sf -H "Authorization: token $token" -H "Accept: application/vnd.forgejo.v1+json, application/json" "$base_url/api/v1$endpoint?limit=50&page=$page")

    if [[ -z "$response" || "$response" == "null" ]]; then
      break
    fi

    results=$(echo "$results" "$response" | jq -s 'if .[1] | type == "array" then .[0] + .[1] else .[0] + [.[1]] end')

    local count
    count=$(echo "$response" | jq 'if type == "array" then length else 1 end')

    if [[ "$count" -lt 50 || "$endpoint" == "/user" ]]; then
      break
    fi
    page=$((page + 1))
  done
  echo "$results"
}

fj_post() {
  local target="$1"
  local endpoint="$2"
  local data="$3"
  local token="${FORGEJO_TOKENS[$target]:-}"

  local base_url="$target"
  if [[ ! "$base_url" =~ ^https?:// ]]; then
    base_url="https://$base_url"
  fi
  base_url="${base_url%/}"

  local response http_code
  response=$(curl -s -w "\n%{http_code}" -X POST -H "Authorization: token $token" -H "Accept: application/vnd.forgejo.v1+json, application/json" -H "Content-Type: application/json" -d "$data" "$base_url/api/v1$endpoint")
  http_code=$(echo "$response" | tail -1)
  response=$(echo "$response" | sed '$d')

  # Debug: log creation response
  if [[ "$endpoint" == "/user/keys" ]]; then
    echo "  DEBUG (creation response): $response" >&2
  fi

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$response"
  else
    echo "  ERROR (HTTP $http_code): $(echo "$response" | jq -r '.message // "unknown error"')" >&2
    return 1
  fi
}


fj_delete() {
  local target="$1"
  local endpoint="$2"
  local token="${FORGEJO_TOKENS[$target]:-}"

  local base_url="$target"
  if [[ ! "$base_url" =~ ^https?:// ]]; then
    base_url="https://$base_url"
  fi
  base_url="${base_url%/}"

  curl -sf -X DELETE -H "Authorization: token $token" "$base_url/api/v1$endpoint"
}

# Extract key material (type + base64) from a full public key line, stripping comments
key_material() {
  echo "$1" | awk '{print $1, $2}'
}

# Collect local keys: map of "key_material" -> "title"
declare -A local_keys=()
declare -A local_key_full=()
declare -A local_key_source=()

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
  local_key_source["$km"]="$pub_file"
done

echo "Found ${#local_keys[@]} local .pub file(s) in $KEY_DIR"
echo

for host in "${!FORGEJO_TOKENS[@]}"; do
  echo "Processing Forgejo instance: $host"

  token="${FORGEJO_TOKENS[$host]}"
  base_url="$host"
  if [[ ! "$base_url" =~ ^https?:// ]]; then
    base_url="https://$base_url"
  fi
  base_url="${base_url%/}"

  # Version check
  version_info=$(curl -sf -H "Authorization: token $token" "$base_url/api/v1/version" || echo '{"version": "unknown"}')
  echo "  Forgejo Version: $(echo "$version_info" | jq -r '.version // "unknown"')"

  # Verify token and identity
  user_info=$(fj_get "$host" "/user")
  if [[ -z "$user_info" ]]; then
    echo "  Error: Could not verify identity on $host. Check your token."
    continue
  fi
  username=$(echo "$user_info" | jq -r '.[0].login // .login')
  echo "  Authenticated as: $username"

  # Fetch existing SSH keys
  remote_keys=$(fj_get "$host" "/user/keys")

  # Debug: Check GPG keys for structure comparison
  gpg_keys=$(fj_get "$host" "/user/gpg_keys")
  echo "  DEBUG (GPG keys list): $(echo "$gpg_keys" | jq -c '.[0] // empty')"
  if [[ -n "$gpg_keys" && "$gpg_keys" != "[]" ]]; then
    echo "  DEBUG (GPG key fields): $(echo "$gpg_keys" | jq -r '.[0] | keys | join(", ")')"
  fi

  # Build maps of ALL remote keys and managed keys
  declare -A all_remote_titles=()
  declare -A all_remote_ids=()
  declare -A remote_ids=()
  declare -A remote_titles=()
  declare -A remote_verified=()
  declare -A remote_tokens=()

  while IFS=$'\t' read -r id title key verified verify_token; do
    [[ -z "$id" ]] && continue
    km="$(key_material "$key")"
    all_remote_titles["$km"]="$title"
    all_remote_ids["$km"]="$id"
    if [[ "$title" == "${PREFIX}"* ]]; then
      remote_ids["$km"]="$id"
      remote_titles["$km"]="$title"
      # Normalize verified to true/false string
      if [[ "$verified" == "true" ]]; then
        remote_verified["$km"]="true"
      else
        remote_verified["$km"]="false"
      fi
      remote_tokens["$km"]="${verify_token:-}"
    fi
  done < <(echo "$remote_keys" | jq -r '.[] | [.id, .title, .key, .verified, .verify_token] | map(if . == null then "" else tostring end) | @tsv')

  echo "Found ${#remote_ids[@]} managed remote key(s) on $host"
  echo

  # Add missing keys
  for km in "${!local_keys[@]}"; do
    title="${local_keys["$km"]}"
    full_key="${local_key_full["$km"]}"
    pub_file="${local_key_source["$km"]}"
    key_json=$(jq -n --arg title "$title" --arg key "$full_key" '{title: $title, key: $key}')

    current_id=""
    is_verified="false"
    token=""

    if [[ -n "${remote_ids["$km"]+x}" ]]; then
      current_id="${remote_ids["$km"]}"
      is_verified="${remote_verified["$km"]}"
      token="${remote_tokens["$km"]}"

      # If list view didn't provide token/verified status, fetch detail
      detail=$(fj_get "$host" "/user/keys/$current_id")

      # Targeted debug for the key you manually verified
      if [[ "$title" == "managed-heartofgold" ]]; then
        echo "  DEBUG (managed-heartofgold raw): $detail" >&2
        echo "  DEBUG (managed-heartofgold keys): $(echo "$detail" | jq -r 'keys | join(", ")')" >&2
      fi

      is_verified=$(echo "$detail" | jq -r '.verified | tostring')
      token=$(echo "$detail" | jq -r '.verify_token | tostring')

      if [[ "$is_verified" == "null" || "$is_verified" == "" ]]; then is_verified="false"; fi

      echo "Unchanged key: $title (Verified: $is_verified)"
    elif [[ -n "${all_remote_titles["$km"]+x}" ]]; then
      old_title="${all_remote_titles["$km"]}"
      old_id="${all_remote_ids["$km"]}"
      echo "Renaming key: '$old_title' -> '$title' (delete+re-add)"
      fj_delete "$host" "/user/keys/$old_id"
      resp=$(fj_post "$host" "/user/keys" "$key_json")
      current_id=$(echo "$resp" | jq -r '.id // empty')
      token=$(echo "$resp" | jq -r '.verify_token // empty')
    else
      echo "Adding key: $title"
      resp=$(fj_post "$host" "/user/keys" "$key_json")
      current_id=$(echo "$resp" | jq -r '.id // empty')
      token=$(echo "$resp" | jq -r '.verify_token // empty')
    fi

    # Automate verification if not already verified
    if [[ "$is_verified" == "false" && -n "$current_id" && -n "$token" && "$token" != "null" ]]; then
      age_file="${pub_file%.pub}.age"
      if [[ ! -f "$age_file" ]]; then
          # Fallback: check if removing .ssh helps (e.g. yubikey.ssh.pub -> yubikey.age)
          alt_age_file="$(dirname "$pub_file")/$(basename "$pub_file" .ssh.pub).age"
          if [[ -f "$alt_age_file" ]]; then
              age_file="$alt_age_file"
          fi
      fi

      if [[ -f "$age_file" ]]; then
        echo "  Attempting to verify key: $title using $age_file"
        tmp_key=$(mktemp)
        chmod 600 "$tmp_key"
        if age -d -i ~/.ssh/id_ed25519 "$age_file" > "$tmp_key" 2>/dev/null; then
          # Try signing with 'forgejo' namespace, fallback to 'gitea'
          for ns in forgejo gitea; do
            signature=$(echo -n "$token" | ssh-keygen -Y sign -n "$ns" -f "$tmp_key" 2>/dev/null || true)
            if [[ -n "$signature" ]]; then
              if [[ ! "$signature" == *"BEGIN SSH SIGNATURE"* ]]; then
                 if [[ -f "${tmp_key}.sig" ]]; then
                   signature=$(cat "${tmp_key}.sig")
                   rm -f "${tmp_key}.sig"
                 fi
              fi

              if [[ "$signature" == *"BEGIN SSH SIGNATURE"* ]]; then
                verify_json=$(jq -n --arg sig "$signature" '{signature: $sig}')
                if fj_post "$host" "/user/keys/$current_id/verify" "$verify_json" >/dev/null 2>&1; then
                  echo "  Successfully verified key: $title (using $ns namespace)"
                  is_verified="true"
                  break
                fi
              fi
            fi
          done
        else
          echo "  Warning: Could not decrypt private key for $title to automate verification."
        fi
        rm -f "$tmp_key"
      fi
    fi

    if [[ "$is_verified" == "false" ]]; then
       if [[ -z "$token" || "$token" == "null" ]]; then
         echo "  Note: Key is unverified but no token was provided by the API."
       else
         echo "  Note: Key is unverified but no matching .age file was found."
       fi
    fi
  done

  echo

  # Remove managed remote keys not present locally
  for km in "${!remote_ids[@]}"; do
    if [[ -z "${local_keys["$km"]+x}" ]]; then
      id="${remote_ids["$km"]}"
      title="${remote_titles["$km"]}"
      echo "Removing key: $title (id=$id)"
      fj_delete "$host" "/user/keys/$id"
    fi
  done

  echo

done

echo "Done."
