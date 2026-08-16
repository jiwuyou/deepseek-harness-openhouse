# DeepSeek Harness for OpenHouse

This repository documents and packages the integration that runs [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) as an OpenHouse small app.

The integration keeps the service-manager daemon in Termux native, runs dsh inside an Ubuntu `proot-distro` container, and exposes the dsh Web UI and service controls through OpenHouse.

## Architecture

```text
OpenHouse desktop
  +-- WebView: http://127.0.0.1:23090/
  +-- service controls: service-manager://services/deepseek-harness

service-manager (Termux native)
  +-- provider: proot-distro
      +-- Ubuntu /root/deepseek-harness
          +-- /root/.local/node/bin/node
              +-- apps/cli/lib/bin.js web --port 23090
```

Ubuntu/proot is intentional. Upstream dsh uses glibc native modules and Linux sandbox mechanisms that are not directly compatible with Android Bionic and Termux. See [Termux compatibility](docs/termux-compatibility.md).

## Repository layout

```text
deepseek-harness-openhouse/
├── wuxianpi-package.json
├── service/
│   └── service.json
├── openhouse/
│   ├── app.json
│   └── component.dev.json
├── scripts/
│   ├── install.sh
│   ├── register-dev.sh
│   ├── setup-ubuntu.sh
│   └── verify.sh
└── docs/
    ├── termux-compatibility.md
    ├── troubleshooting.md
    └── upstream-mirrors.md
```

`openhouse/app.json` is the formal `openhouse.app` package contribution. `openhouse/component.dev.json` is only for direct registration while developing outside WuxianPi Package Manager.

## Prerequisites

- Termux native environment
- `proot-distro` with an Ubuntu container
- OpenHouse service-manager running with its canonical configuration
- WuxianPi Package Manager for formal installation, or the development scripts below
- Free local port `23090`

Install Ubuntu when needed:

```bash
pkg install proot-distro
proot-distro install ubuntu
```

## Development installation

Run from Termux native:

```bash
cd ~/deepseek-harness-openhouse
chmod +x scripts/*.sh
./scripts/install.sh
```

The script performs three stages:

1. Runs `scripts/setup-ubuntu.sh` inside Ubuntu.
2. Installs nvm, Node.js 22, pnpm 11.7.0, clones dsh to `/root/deepseek-harness`, installs dependencies, and builds both the nested Landlock workspace and the main workspace.
3. Registers the ServiceSpec and development OpenHouse component, starts the service, and verifies HTTP access.

If a development service named `deepseek-harness` is already registered, replacement is explicit:

```bash
./scripts/install.sh --replace
```

This stops and deletes the existing service before registering the repository version. It does not delete the dsh checkout, settings, sessions, or credentials.

## Manual Ubuntu setup

Run the setup stage directly when diagnosing installation issues:

```bash
proot-distro login ubuntu
bash /data/data/com.termux/files/home/deepseek-harness-openhouse/scripts/setup-ubuntu.sh
```

The script creates `/root/.local/node` as a stable link to the selected nvm Node.js installation. The ServiceSpec uses that link so it does not depend on a specific Node 22 patch version.

Manual smoke test inside Ubuntu:

```bash
cd /root/deepseek-harness
/root/.local/node/bin/node apps/cli/lib/bin.js web --port 3080
```

## Formal WuxianPi package

The package manifest contributes:

- `service-manager.service` from `service/service.json`
- `openhouse.app` from `openhouse/app.json`

For a formal release, publish an immutable Git commit and register that approved commit through WuxianPi Package Manager. The package contribution mechanism should own registration and removal. Do not run `register-dev.sh` on top of a package-managed installation. Development registration is API-owned and intentionally does not copy the ServiceSpec into `services.d`, because using both mechanisms would create duplicate services after a service-manager reload.

The package deliberately does not clone or build upstream dsh as a package build artifact. Current WuxianPi service contributions do not expose a stable runtime package-root placeholder, while dsh itself is a large mutable source checkout. The host preparation step therefore deploys dsh to the stable guest path `/root/deepseek-harness` before enabling the contribution.

## Service design

Important parts of [service.json](service/service.json):

- `provider: proot-distro` starts the process in Ubuntu while service-manager remains native to Termux.
- `working_dir: /root/deepseek-harness` keeps dsh profile and workspace resolution anchored to the checkout.
- `/root/.local/node/bin/node` selects the tested nvm Node.js 22 installation.
- `apps/cli/lib/bin.js` is the built CLI entry; using it avoids slow runtime TypeScript transformation.
- Guest `PATH`, `HOME`, and `TMPDIR` are reconstructed after removing Termux linker variables.
- The process stays in the foreground so service-manager owns it directly.
- TCP health checks tolerate dsh's relatively slow initialization.
- Port `23090` is fixed because the OpenHouse WebView URL is static.
- The service binds only to `127.0.0.1`.

`service-manager-guest` in the command array is the `$0` argument to `sh -lc`, not an executable.

## Verification

```bash
./scripts/verify.sh
```

The verifier checks:

- JSON syntax for all package contributions
- shell syntax for installation scripts
- service-manager reports `running`
- runtime endpoint publication includes port `23090`
- the Web UI returns HTTP 200

Useful API commands:

```bash
SM_CONFIG="${SMALLPHONEAI_OPENHOUSE_SERVICE_MANAGER_CONFIG:-$HOME/.config/openhouseai/service-manager/config.json}"
SM_URL="${SERVICE_MANAGER_URL:-http://127.0.0.1:20087}"
TOKEN="$(service-manager token show --config "$SM_CONFIG" | head -n1)"

curl -fsS -H "Authorization: Bearer $TOKEN" \
  "$SM_URL/api/v1/services/deepseek-harness/status"

curl -fsS -H "Authorization: Bearer $TOKEN" \
  "$SM_URL/api/v1/services/deepseek-harness/logs?limit=50"

curl -fsS -X POST -H "Authorization: Bearer $TOKEN" \
  "$SM_URL/api/v1/services/deepseek-harness/restart"
```

Never commit or print the service-manager token.

## Credentials

The Web UI starts without a model API key, but agent requests require credentials. Configure them through the dsh Models/Credentials UI or its documented managed credential file. Do not add API keys to this repository, `.env` examples, service manifests, URLs, or OpenHouse component metadata.

## Operational notes

- The built CLI normally becomes ready in roughly 20-60 seconds on the tested device.
- The service's logs should eventually contain `dsh web: http://127.0.0.1:23090`.
- If port `23090` must change, update both service and OpenHouse manifests together.
- Persistent dsh state lives in the Ubuntu root filesystem and is not removed by unregistering this integration.
- Do not keep the service alive with tmux or nohup; service-manager is the lifecycle owner.

See [Troubleshooting](docs/troubleshooting.md) for known failure modes.

## Upstream ownership

This repository is an integration package, not a fork of DeepSeek Harness. dsh source code and licensing remain with the upstream project. Integration issues belong here; upstream runtime defects should be reproduced against the upstream checkout before reporting them there.

The authoritative source is `https://github.com/deepseek-ai/deepseek-harness`. Confirmed GitCode and AtomGit mirrors, commit comparison commands, and supply-chain guidance are documented in [Upstream mirrors](docs/upstream-mirrors.md).
