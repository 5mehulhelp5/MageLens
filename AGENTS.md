# Repository guide for AI coding agents

## Project identity and starting points

MageLens is a Docker-based Magento 2 development and E2E coverage environment. It coordinates PHP line coverage with the PCOV fork, JavaScript statement coverage with Istanbul, and HTML/PHTML execution coverage with `@vitaliiboiko/magento-template-coverage`. It supports Cypress or Playwright and Luma, Hyvä CSP or legacy Hyvä.

Read [README.md](README.md), [docs/coverage.md](docs/coverage.md) and [tests/README.md](tests/README.md). This is local development tooling, not a production deployment configuration.

## Architecture and navigation

| Path | Responsibility |
| --- | --- |
| `install.sh` → `bin/install` | Install/update entry point and selected theme/runner setup |
| `bin/common`, `bin/dependencies`, `bin/application-compose` | Dependency loading, Docker preflight, Compose overlays and workflow locking |
| `dependencies.yaml`, `bin/sync-dependencies.cjs` | Installation version inputs and package synchronization |
| `compose.yaml`, `docker/php/Dockerfile`, `docker/runner/Dockerfile` | Services based on Mark Shust's Docker Magento and runner-specific images |
| `bin/project.cjs`, `docker/php/project.php`, `docker/php/theme-scope.php` | Source/module/theme discovery and active coverage roots |
| `bin/run-coverage` | Locked prepare → fixtures → warm-up → collection → tests → reports lifecycle |
| `bin/runner`, `docker/runner/` | Shared Docker command helper, headed browser desktop, noVNC viewer and health checks for either runner |
| `bin/prepare.cjs`, `bin/javascript-scope.cjs` | Disposable instrumentation, source hashes, zero-hit baselines and fresh run identity |
| `docker/php/manifest.php`, `docker/php/collection.php`, `docker/php/collect.php` | PHP manifest preparation and HTTP collection |
| `docker/php/report.php`, `docker/php/report-data.php` | PHP coverage reporting |
| `bin/run-browser.cjs`, `cypress.config.cjs`, `cypress/support/` | Cypress execution and collection |
| `bin/run-playwright.cjs`, `playwright.config.cjs`, `playwright/` | Playwright execution, fixtures and reporter |
| `bin/report-browser.cjs`, `bin/finalize.cjs`, `bin/report-index.cjs`, `bin/badges.cjs` | Browser reports, integrity checks, combined report and README badges |
| `src/app/code/Application/Blog/` | Demonstration Magento module; read its scoped `AGENTS.md` |
| `src/app/design/frontend/Application/coverage/` | Demonstration theme |
| `tests/` | Node/PHP checks, isolated installations, compatibility fixtures and matrix verification |

`src/` also holds the locally installed Magento tree. Only application source areas are tracked; inspect Git status before editing generated/vendor content. `.runtime/` holds disposable copies, generated Compose files, installation profile, upstream checkout and PCOV state. Edit tracked sources, not runtime copies.

## Commands and validation

Run commands from the repository root. `package.json` defines:

| Command | Purpose and prerequisites |
| --- | --- |
| `npm run test:integration` | Fast Node test suite: `node --test tests/*.test.cjs`; install locked npm dependencies first and inspect relevant tests for PHP/subprocess requirements |
| `npm run test:e2e` | `bash tests/e2e-isolated.sh`: fresh temporary Magento installation, browser suite and report verification |
| `npm run test:e2e:matrix` | `bash tests/e2e-matrix.sh`: six isolated Luma/Hyvä CSP/legacy Hyvä × Cypress/Playwright installations |
| `./bin/run-coverage` | Full Docker coverage run with the saved runner; `npm run coverage` and legacy `npm run cy:coverage` are host-side aliases |
| `./bin/runner COMMAND` | Run Node, npm, a shell or another command in the selected runner container; upstream `bin/node` and `bin/npm` target the Magento application |

For host-side integration dependencies, `npm ci --ignore-scripts` installs from the lockfile without downloading Cypress through its install hook; actual browser runs require their runner installation. Use `node --test tests/prepare.test.cjs` or another existing test file for a targeted check, then the integration suite for shared orchestration changes. PHP tests live in `tests/*.test.php`; inspect each bootstrap before selecting host versus container execution. Use `php -l`, `node --check` and `bash -n` on changed files as appropriate.

Docker must be available with Compose 2.24.4+; E2E installation needs network access and Magento Marketplace credentials. Supply `MAGELENS_COMPOSER_AUTH_FILE` or `MAGELENS_COMPOSER_AUTH_VOLUME` as documented in `tests/README.md`, never inline secrets. Matrix theme/runner selection uses `MAGELENS_E2E_THEME` and `MAGELENS_E2E_RUNNER`. Tests retain reports under `.runtime/e2e/`; they clean only their own temporary Compose projects and volumes.

Use `./install.sh` with the intended `--hyva`, `--nocsp` and/or `--playwright` flags for a requested installation change. It is not a harmless lint command: installation can modify Magento setup, credentials/configuration, services and host domain/certificate setup. Prefer the isolated test harness, which uses container-only setup, for validation. See `tests/README.md` for testing a local template-coverage tarball.

The checked-in GitHub workflow is release automation; do not assume a PR automatically runs the local integration or six-installation matrix.

## Coverage and safety invariants

- Instrument disposable copies only; preserve original source bytes and PHP line numbers. Keep symlink rejection and final source-hash checks.
- Do not bypass `.runtime/workflow.lock`, run install/coverage concurrently, or remove a lock without checking for an active workflow.
- Warm-up occurs before collection in a separate browser. Fresh run IDs and zero-hit baselines must prevent stale or warm-up execution from inflating coverage.
- Both runners use the same container desktop and read-only noVNC viewer, including headed warm-up. Keep helper commands and service lifecycle independent of runner choice. `RUNNER_VIEW_PORT` takes precedence over the legacy `CYPRESS_VIEW_PORT`; keep that fallback when updating Compose, nginx and viewer URLs. Runtime installation marker `3` requires older installs to rebuild before running headed Playwright.
- Preserve fixture and collection cleanup on failure/interruption. Default coverage must not restart services, clear caches or refresh assets; those are explicit options.
- PHP executable lines, whole-file JavaScript statements and template executable lines are separate metrics. Inline HTML/PHTML scripts belong to template coverage. DOM presence is separate from execution.
- Keep eligible unvisited files uncovered, inactive themes excluded and vendor roots opt-in. Do not improve percentages by removing difficult files or bypassing required-execution checks.
- Keep run-ID, source-integrity and all-tests-passed checks before publishing reports/badges. Skipped/pending tests must not become a successful published run.
- Never print/commit Composer auth, `.env`, installed `env.php`, certificates or credential volumes. Do not use broad Docker pruning or remove an existing application's volumes.
- Preserve dependency pins and lockfiles together when a dependency change is requested. Do not change versions or publish releases as part of documentation work.

## Review expectations

For orchestration changes, cover failure cleanup and both runner paths. The isolated matrix checks shared viewer access and desktop/browser recovery after graceful and forced stops in all six modes. For shared coverage changes, explain affected theme/runner combinations and use the isolated matrix when available. State exactly which checks passed, which needed unavailable credentials/images/services, and whether source preservation was verified. Exclude generated reports, runtime files and incidental README badge changes from unrelated PRs.
