#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age -p age-plugin-yubikey
# Round-trip agenix secrets through gitignored plaintext copies in plain/,
# mirroring the .age paths (caddy/starhaven-caddyfile.age <-> plain/caddy/starhaven-caddyfile).
#
#   plain.sh decrypt [secret.age ...]   .age -> plain/
#   plain.sh encrypt [secret.age ...]   plain/ -> .age, recipients from secrets.nix
#
# Without secret arguments, acts on every caddy/*.age.
# Decrypted copies take the mtime of their .age, so encrypt only touches secrets
# whose plaintext was edited (re-encrypting changes the ciphertext, which
# restarts the service via restartTriggers), and decrypt refuses to overwrite
# unencrypted edits.
set -euo pipefail
cd "$(dirname "$0")"

IDENTITY=${AGE_IDENTITY:-$HOME/.ssh/id_ed25519}
mode=${1:-}
shift || true
secrets=("$@")
[ ${#secrets[@]} -eq 0 ] && secrets=(caddy/*.age)

for s in "${secrets[@]}"; do
  s=${s#secrets/} # also accept paths relative to the repo root
  plain=plain/${s%.age}
  case $mode in
  decrypt)
    if [ "$plain" -nt "$s" ]; then
      echo "skip $s: $plain has unencrypted edits (encrypt or delete it first)" >&2
      continue
    fi
    mkdir -p "$(dirname "$plain")"
    (umask 077 && age -d -i "$IDENTITY" -o "$plain" "$s")
    touch -r "$s" "$plain"
    echo "$s -> $plain"
    ;;
  encrypt)
    [ -f "$plain" ] || { echo "skip $s: no $plain" >&2; continue; }
    [ "$plain" -nt "$s" ] || { echo "unchanged $s"; continue; }
    age -o "$s.tmp" -R <(nix eval --raw --file secrets.nix \
      --apply "s: builtins.concatStringsSep \"\n\" s.\"$s\".publicKeys") "$plain"
    mv "$s.tmp" "$s"
    touch -r "$s" "$plain"
    echo "$plain -> $s"
    ;;
  *)
    echo "usage: $0 decrypt|encrypt [secret.age ...]" >&2
    exit 1
    ;;
  esac
done
