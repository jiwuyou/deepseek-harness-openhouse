#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SM_CONFIG="${SMALLPHONEAI_OPENHOUSE_SERVICE_MANAGER_CONFIG:-$HOME/.config/openhouseai/service-manager/config.json}"
SM_URL="${SERVICE_MANAGER_URL:-http://127.0.0.1:20087}"
SERVICE_NAME="deepseek-harness"
REPLACE="${1:-}"

if [[ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]]; then
  echo "Run this script in Termux native, not inside Ubuntu." >&2
  exit 1
fi
command -v service-manager >/dev/null
command -v proot-distro >/dev/null
command -v python3 >/dev/null
command -v curl >/dev/null

if ! proot-distro login ubuntu -- test -x /root/.local/node/bin/node; then
  echo "Missing /root/.local/node/bin/node in Ubuntu. Run scripts/setup-ubuntu.sh there first." >&2
  exit 1
fi
if ! proot-distro login ubuntu -- test -f /root/deepseek-harness/apps/cli/lib/bin.js; then
  echo "Missing built DeepSeek Harness CLI at /root/deepseek-harness/apps/cli/lib/bin.js." >&2
  exit 1
fi

TOKEN="$(service-manager token show --config "$SM_CONFIG" | head -n1)"
if [[ -z "$TOKEN" ]]; then
  echo "Could not read the service-manager token from $SM_CONFIG." >&2
  exit 1
fi

existing_id="$(curl -fsS -H "Authorization: Bearer $TOKEN" "$SM_URL/api/v1/services" | python3 -c '
import json, sys
for item in json.load(sys.stdin):
    if item.get("spec", {}).get("name") == "deepseek-harness":
        print(item["id"])
        break
')"

if [[ -n "$existing_id" ]]; then
  if [[ "$REPLACE" != "--replace" ]]; then
    echo "Service already exists as $existing_id. Re-run with --replace to replace it." >&2
    exit 1
  fi
  curl -fsS -X POST -H "Authorization: Bearer $TOKEN" \
    "$SM_URL/api/v1/services/$existing_id/stop" >/dev/null 2>&1 || true
  curl -fsS -X DELETE -H "Authorization: Bearer $TOKEN" \
    "$SM_URL/api/v1/services/$existing_id" >/dev/null
fi

spec_file="$(mktemp)"
trap 'rm -f "$spec_file"' EXIT
python3 - "$ROOT_DIR/service/service.json" "$spec_file" <<'PY'
import json, sys
source, target = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    manifest = json.load(handle)
with open(target, "w", encoding="utf-8") as handle:
    json.dump(manifest["service"], handle, ensure_ascii=False)
PY

response="$(curl -fsS -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "@$spec_file" \
  "$SM_URL/api/v1/services")"
service_id="$(printf '%s' "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"

mkdir -p "$HOME/.config/openhouseai/service-manager/services.d"
cp "$ROOT_DIR/service/service.json" \
  "$HOME/.config/openhouseai/service-manager/services.d/deepseek-harness.json"

mkdir -p "$HOME/.config/openhouseai/components.d"
cp "$ROOT_DIR/openhouse/component.dev.json" \
  "$HOME/.config/openhouseai/components.d/deepseek-harness.json"

curl -fsS -X POST -H "Authorization: Bearer $TOKEN" \
  "$SM_URL/api/v1/services/$service_id/start" >/dev/null

printf 'Registered service: %s\n' "$service_id"
printf 'OpenHouse entry: http://127.0.0.1:23090/\n'
