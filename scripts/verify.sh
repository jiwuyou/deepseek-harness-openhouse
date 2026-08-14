#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SM_CONFIG="${SMALLPHONEAI_OPENHOUSE_SERVICE_MANAGER_CONFIG:-$HOME/.config/openhouseai/service-manager/config.json}"
SM_URL="${SERVICE_MANAGER_URL:-http://127.0.0.1:20087}"
SERVICE_NAME="deepseek-harness"

python3 -m json.tool "$ROOT_DIR/wuxianpi-package.json" >/dev/null
python3 -m json.tool "$ROOT_DIR/service/service.json" >/dev/null
python3 -m json.tool "$ROOT_DIR/openhouse/app.json" >/dev/null
python3 -m json.tool "$ROOT_DIR/openhouse/component.dev.json" >/dev/null
bash -n "$ROOT_DIR/scripts/setup-ubuntu.sh"
bash -n "$ROOT_DIR/scripts/register-dev.sh"
bash -n "$ROOT_DIR/scripts/install.sh"

TOKEN="$(service-manager token show --config "$SM_CONFIG" | head -n1)"
status="$(curl -fsS -H "Authorization: Bearer $TOKEN" \
  "$SM_URL/api/v1/services/$SERVICE_NAME/status")"
python3 - "$status" <<'PY'
import json, sys
status = json.loads(sys.argv[1])
print(f"service state: {status.get('state')}")
print(f"provider: {status.get('provider')}")
print(f"pid: {status.get('pid')}")
if status.get("state") != "running":
    raise SystemExit(1)
PY

endpoint="$(python3 - "$HOME/.config/openhouseai/runtime/endpoints.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    endpoints = json.load(handle).get("endpoints", [])
for endpoint in endpoints:
    if endpoint.get("serviceId") and endpoint.get("name") == "web" and endpoint.get("port") == 23090:
        print(endpoint.get("url", ""))
        break
PY
)"
if [[ -z "$endpoint" ]]; then
  echo "No published web endpoint on port 23090." >&2
  exit 1
fi

http_code="$(curl -sS -o /dev/null -w '%{http_code}' "$endpoint")"
if [[ "$http_code" != "200" ]]; then
  echo "Web endpoint returned HTTP $http_code: $endpoint" >&2
  exit 1
fi

printf 'endpoint: %s\n' "$endpoint"
printf 'HTTP status: %s\n' "$http_code"
printf 'manifests and shell syntax: OK\n'
