#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

KRL="${KRL:-$SCRIPT_DIR/krl}"
CA_PUB="${CA_PUB:-$SCRIPT_DIR/ca.pub}"

usage() {
    cat <<EOF
Usage: $0 <method> <argument>

Methods:
  key   <pubkey-file>   Revoke a specific public key (and any cert signed from it)
  id    <identity>      Revoke all certs with the given Key ID (the -I value used at signing)
  serial <number>       Revoke a cert by serial number (the -z value used at signing)

Environment:
  KRL      Path to the KRL file (default: \$SCRIPT_DIR/krl)
  CA_PUB   Path to the CA public key (default: \$SCRIPT_DIR/ca.pub)

Examples:
  $0 key    user/heartofgold.pub
  $0 id     kai-heartofgold
  $0 serial 1745188800

After revoking, commit the updated krl file and push — the auto-update service
will deploy it to servers within the hour.
EOF
    exit 1
}

[[ $# -ne 2 ]] && usage

METHOD="$1"
ARG="$2"

if [[ ! -f "$KRL" ]]; then
    echo "error: KRL not found at $KRL" >&2
    echo "       Create an empty one with: ssh-keygen -k -f $KRL" >&2
    exit 1
fi

case "$METHOD" in
    key)
        [[ "$ARG" != /* ]] && ARG="$SCRIPT_DIR/$ARG"
        if [[ ! -f "$ARG" ]]; then
            echo "error: public key file not found: $ARG" >&2
            exit 1
        fi
        echo "==> Revoking by public key: $ARG"
        ssh-keygen -k -f "$KRL" -u "$ARG"
        ;;
    id)
        if [[ ! -f "$CA_PUB" ]]; then
            echo "error: CA public key not found at $CA_PUB (required for key ID revocation)" >&2
            exit 1
        fi
        echo "==> Revoking by Key ID: $ARG"
        printf 'id: %s\n' "$ARG" | ssh-keygen -k -f "$KRL" -s "$CA_PUB" -u -
        ;;
    serial)
        if [[ ! -f "$CA_PUB" ]]; then
            echo "error: CA public key not found at $CA_PUB (required for serial revocation)" >&2
            exit 1
        fi
        echo "==> Revoking serial: $ARG"
        printf 'serial: %s\n' "$ARG" | ssh-keygen -k -f "$KRL" -s "$CA_PUB" -u -
        ;;
    *)
        echo "error: unknown method '$METHOD'" >&2
        usage
        ;;
esac

echo ""
echo "✓ KRL updated: $KRL"
echo ""
echo "Current KRL contents:"
ssh-keygen -Q -l -f "$KRL" 2>/dev/null || echo "  (empty or unable to list — this is normal for a new KRL)"
echo ""
echo "Next: commit secrets/ssh/krl and push."
echo "      The auto-update service will deploy it to all servers within the hour."
