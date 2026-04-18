#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age openssh

set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $(basename "$0") <hostname> [extra-public-key]" >&2
  echo "" >&2
  echo "  extra-public-key  Additional SSH public key string to encrypt for" >&2
  echo "                    (e.g. the target host's /etc/ssh/ssh_host_ed25519_key.pub)" >&2
  exit 1
fi

HOSTNAME="$1"
EXTRA_PUBKEY="${2:-}"

# Resolve paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="$(dirname "$SCRIPT_DIR")"

PUBKEY_FILE="${SCRIPT_DIR}/${HOSTNAME}.pub"
AGE_FILE="${SCRIPT_DIR}/${HOSTNAME}.age"

# Guard against overwriting existing keys
for f in "$PUBKEY_FILE" "$AGE_FILE"; do
  if [ -e "$f" ]; then
    echo "error: $f already exists, aborting" >&2
    exit 1
  fi
done

# Generate key pair in a temporary directory
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ssh-keygen -t ed25519 -C "kai@${HOSTNAME}" -f "${WORK}/id_ed25519" -N "" -q

# Save public key (plain text)
cp "${WORK}/id_ed25519.pub" "$PUBKEY_FILE"

# Build recipients file: masterKeys from public_keys.nix + the new key
RECIPIENTS="${WORK}/recipients"

# NOTE: this list must match masterKeys in secrets/secrets.nix.
nix eval --raw --impure --expr "
  builtins.concatStringsSep \"\n\" (import ${SECRETS_DIR}/master_keys.nix)
" > "$RECIPIENTS"

# Add the newly generated key itself as a recipient
echo "" >> "$RECIPIENTS"
cat "${WORK}/id_ed25519.pub" >> "$RECIPIENTS"

# Add optional extra public key (e.g. host SSH key for initial bootstrap)
if [ -n "$EXTRA_PUBKEY" ]; then
  echo "$EXTRA_PUBKEY" >> "$RECIPIENTS"
fi

# Encrypt private key
age -R "$RECIPIENTS" -o "$AGE_FILE" "${WORK}/id_ed25519"

echo "Generated SSH key pair for '${HOSTNAME}':"
echo "  Public:  ${PUBKEY_FILE}"
echo "  Private: ${AGE_FILE} (age-encrypted)"
echo ""
ssh-keygen -lf "$PUBKEY_FILE"
echo ""
echo "Next steps:"
echo "  1. Add 'ssh/${HOSTNAME}.age' to secrets/secrets.nix"
echo "  2. Commit both files"
