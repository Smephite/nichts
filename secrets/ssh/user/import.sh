#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age openssh
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "Usage: $(basename "$0") <hostname> <private-key-path> [extra-public-key]" >&2
  echo "" >&2
  echo "  private-key-path  Path to an existing SSH private key (e.g. ~/.ssh/id_ed25519)" >&2
  echo "  extra-public-key  Additional SSH public key string to encrypt for" >&2
  echo "                    (e.g. the target host's /etc/ssh/ssh_host_ed25519_key.pub)" >&2
  exit 1
fi

HOSTNAME="$1"
PRIVKEY_PATH="$2"
EXTRA_PUBKEY="${3:-}"

# Validate the private key exists
if [ ! -f "$PRIVKEY_PATH" ]; then
  echo "error: $PRIVKEY_PATH does not exist" >&2
  exit 1
fi

# Derive the public key path (convention: <private>.pub)
PRIVKEY_PUBPATH="${PRIVKEY_PATH}.pub"
if [ ! -f "$PRIVKEY_PUBPATH" ]; then
  echo "error: expected public key at $PRIVKEY_PUBPATH but it does not exist" >&2
  exit 1
fi

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

# Save public key (plain text)
cp "$PRIVKEY_PUBPATH" "$PUBKEY_FILE"

# Build recipients file: masterKeys + the key itself
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
RECIPIENTS="${WORK}/recipients"

nix eval --raw --impure --expr "
  builtins.concatStringsSep \"\n\" (import ${SECRETS_DIR}/master_keys.nix)
" > "$RECIPIENTS"

echo "" >> "$RECIPIENTS"
cat "$PRIVKEY_PUBPATH" >> "$RECIPIENTS"

if [ -n "$EXTRA_PUBKEY" ]; then
  echo "$EXTRA_PUBKEY" >> "$RECIPIENTS"
fi

# Encrypt private key
age -R "$RECIPIENTS" -o "$AGE_FILE" "$PRIVKEY_PATH"

echo "Imported SSH key pair for '${HOSTNAME}':"
echo "  Public:  ${PUBKEY_FILE}"
echo "  Private: ${AGE_FILE} (age-encrypted)"
echo ""
ssh-keygen -lf "$PUBKEY_FILE"
