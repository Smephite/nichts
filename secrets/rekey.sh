#!/usr/bin/env nix-shell
#!nix-shell -i bash -p age

TMPKEY=$(mktemp)
trap 'rm -f "$TMPKEY" "$TMPKEY.pub"' EXIT

cp ~/.ssh/id_ed25519 "$TMPKEY"
if ssh-keygen -p -N "" -f "$TMPKEY"; then
  agenix -r -i "$TMPKEY"
fi
