# Troubleshooting

## `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`

The Ubuntu system Node.js build used during testing was incompatible with pnpm 11.7.0. Run dsh with the nvm-installed Node.js 22 selected by `scripts/setup-ubuntu.sh`. The service uses the stable link `/root/.local/node` rather than a version-specific nvm directory.

## `Cannot find package 'tsx' imported from /root/`

This indicates an older ServiceSpec is still launching `apps/cli/src/bin.ts` through `tsx`. The repository ServiceSpec runs the built entry `apps/cli/lib/bin.js`. Run `pnpm run build`, then replace the registered development service.

## Health check reports `Connection refused`

The built CLI can take 20-60 seconds to initialize on a mobile device. The TypeScript source entry is substantially slower and should not be used by service-manager. This service uses a TCP check with a 30-second interval and timeout. Inspect the process and logs before increasing retries:

```bash
scripts/verify.sh
```

## Start API returns HTTP 400

The API returns HTTP 400 when all startup attempts fail. Run curl without `-f` once to read the JSON error body, then inspect service-manager logs and the service logs.

## Port 23090 is already in use

First check for duplicate registrations with the same service name. A development service must be registered through the API only; do not also copy it into `services.d`. The current `register-dev.sh --replace` removes all matching development registrations before creating one service.

The OpenHouse manifest contains a fixed URL, so the service reserves a fixed port. Stop any remaining conflicting service or change port `23090` consistently in:

- `service/service.json`
- `openhouse/app.json`

Do not only change the ServiceSpec, because the desktop webview would still open the old URL.

## `service-manager-guest: not found`

`service-manager-guest` is not an executable. In the command array it becomes `$0` for `sh -lc`; the first argument after it becomes `$1`. Do not remove it without also rewriting the shell argument handling.

## Agent requests fail

The Web UI can run without a model credential, but model calls require configured credentials. Use dsh's managed Models/Credentials UI or its documented credential file. Do not place API keys in this repository, service manifests, URLs, or service-manager tokens.
