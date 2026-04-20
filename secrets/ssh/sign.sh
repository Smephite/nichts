#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssh opensc
set -euo pipefail

# Resolve script directory (follows symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Configuration (paths relative to script location unless overridden)
CA_PUB="${CA_PUB:-$SCRIPT_DIR/ca.pub}"

usage() {
    cat <<EOF
Usage: $0 <public-key-file> [-n principal]... [-I identity] [-V validity]

  public-key-file     Path to the .pub key to sign (relative to script or absolute)
  -n, --principal     Principal name (repeatable; default: \$USER = $USER)
  -I, --identity      Certificate identity (default: <first-principal>-$(hostname -s))
  -V, --validity      Certificate validity (default: +52w)
                      Examples: +1d, +4w, +52w, +1y, 20260101:20270101

Environment:
  CA_PUB              Path to CA public key (default: \$SCRIPT_DIR/ssh/ca.pub)

Examples:
  $0 user/yubikey.pub
  $0 user/yubikey.pub -n kai
  $0 user/yubikey.pub -n kai -n root -n admin
  $0 user/yubikey.pub -n kai -I kai-laptop-2026 -V +2y
  $0 user/contractor.pub -n contractor -V +8h
EOF
    exit 1
}

# Args
KEY_TO_SIGN=""
PRINCIPALS=()
IDENTITY=""
VALIDITY="+52w"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--principal)
            PRINCIPALS+=("$2")
            shift 2
            ;;
        -I|--identity)
            IDENTITY="$2"
            shift 2
            ;;
        -V|--validity)
            VALIDITY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *)
            if [[ -z "$KEY_TO_SIGN" ]]; then
                KEY_TO_SIGN="$1"
            else
                echo "Unexpected argument: $1" >&2
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$KEY_TO_SIGN" ]]; then
    usage
fi

# Default principal and identity
if [[ ${#PRINCIPALS[@]} -eq 0 ]]; then
    PRINCIPALS=("$USER")
fi
if [[ -z "$IDENTITY" ]]; then
    IDENTITY="${PRINCIPALS[0]}-$(hostname -s)"
fi

# Join principals with comma for ssh-keygen -n
PRINCIPALS_CSV=$(IFS=,; echo "${PRINCIPALS[*]}")

# Resolve KEY_TO_SIGN relative to script directory if not absolute
if [[ "$KEY_TO_SIGN" != /* ]]; then
    KEY_TO_SIGN="$SCRIPT_DIR/$KEY_TO_SIGN"
fi

if [[ ! -f "$KEY_TO_SIGN" ]]; then
    echo "Error: key file not found: $KEY_TO_SIGN" >&2
    exit 1
fi

if [[ ! -f "$CA_PUB" ]]; then
    echo "Error: CA public key not found: $CA_PUB" >&2
    exit 1
fi

# Locate PKCS#11 library from the nix-shell-provided opensc
PKCS11_LIB=$(find "$(dirname "$(command -v opensc-tool)")/.." -name "opensc-pkcs11.so" 2>/dev/null | head -1)
if [[ -z "$PKCS11_LIB" ]]; then
    echo "Error: opensc-pkcs11.so not found in nix-shell environment" >&2
    exit 1
fi

echo "==> Signing:     $KEY_TO_SIGN"
echo "==> Identity:    $IDENTITY"
echo "==> Principals:  ${PRINCIPALS[*]}"
echo "==> Validity:    $VALIDITY"
echo "==> CA key:      $CA_PUB"
echo "==> PKCS#11:     $PKCS11_LIB"
echo ""
echo "⚠️  After entering the PIN, TOUCH YOUR YUBIKEY to authorize signing."
echo ""

ssh-keygen \
    -s "$CA_PUB" \
    -D "$PKCS11_LIB" \
    -I "$IDENTITY" \
    -n "$PRINCIPALS_CSV" \
    -V "$VALIDITY" \
    "$KEY_TO_SIGN"

CERT="${KEY_TO_SIGN%.pub}-cert.pub"
echo ""
echo "✓ Certificate written to: $CERT"
echo ""
ssh-keygen -L -f "$CERT" | sed 's/^/    /'
