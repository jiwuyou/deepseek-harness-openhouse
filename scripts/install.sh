#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPLACE="${1:-}"

if [[ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]]; then
  echo "Run this script in Termux native." >&2
  exit 1
fi
command -v proot-distro >/dev/null

if ! proot-distro login ubuntu -- true >/dev/null 2>&1; then
  echo "Ubuntu is not installed. Install it with: proot-distro install ubuntu" >&2
  exit 1
fi

proot-distro login ubuntu -- bash "$ROOT_DIR/scripts/setup-ubuntu.sh"
if [[ "$REPLACE" == "--replace" ]]; then
  "$ROOT_DIR/scripts/register-dev.sh" --replace
else
  "$ROOT_DIR/scripts/register-dev.sh"
fi
"$ROOT_DIR/scripts/verify.sh"
