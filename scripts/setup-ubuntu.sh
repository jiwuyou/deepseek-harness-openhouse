#!/usr/bin/env bash
set -euo pipefail

DSH_REPOSITORY="${DSH_REPOSITORY:-https://github.com/deepseek-ai/deepseek-harness.git}"
DSH_DIR="${DSH_DIR:-/root/deepseek-harness}"
NODE_MAJOR="${NODE_MAJOR:-22}"
PNPM_VERSION="${PNPM_VERSION:-11.7.0}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root inside the Ubuntu proot container." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]] || ! grep -qi ubuntu /etc/os-release; then
  echo "This script must run inside the Ubuntu proot container." >&2
  exit 1
fi

apt-get update
apt-get install -y ca-certificates curl git build-essential python3

export NVM_DIR="/root/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"
nvm install "$NODE_MAJOR"
nvm use "$NODE_MAJOR"
npm install --global "pnpm@${PNPM_VERSION}"

NODE_DIR="$(dirname "$(dirname "$(command -v node)")")"
mkdir -p /root/.local
ln -sfn "$NODE_DIR" /root/.local/node

if [[ -d "$DSH_DIR/.git" ]]; then
  echo "Using existing checkout: $DSH_DIR"
elif [[ -e "$DSH_DIR" ]]; then
  echo "Target exists but is not a Git checkout: $DSH_DIR" >&2
  exit 1
else
  git clone "$DSH_REPOSITORY" "$DSH_DIR"
fi

cd "$DSH_DIR"
pnpm install
pnpm run build

printf '\nDeepSeek Harness is built. Stable Node path: %s\n' /root/.local/node/bin/node
printf 'Manual smoke test: cd %q && pnpm dsh web --port 3080\n' "$DSH_DIR"
