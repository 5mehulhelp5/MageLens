# Release notes

## 1.2.1 - 2026-10-18

- Update template coverage to 1.4.0, linking PHP-rendered JavaScript to child template source files and distinguishing empty, unresolved and unobserved output.
- Verify child-template source attribution, executed functions and uncovered branches in all four Luma/Hyvä and Cypress/Playwright installation checks.

## 1.2.0 — 2026-10-18

- Updated Magento template coverage to 1.3.0. HTML/PHTML bindings, template expressions and inline scripts now share the template report, with script functions and branches mapped to original source lines. PHP executable lines remain in the PHP report.
- JavaScript reports contain whole `.js` files and use statement percentages, with separate application and bundled-library views.
- Added optional vendor coverage roots and explicit JavaScript distribution selection in `coverage.config.json`, including a Hyvä example and checks for required runtime assets.
- Rebuilding Playwright reports no longer counts previously merged hits twice. Stale JavaScript instrumentation is rejected.

After updating, rerun `./install.sh` with your selected theme and runner flags, then `./bin/run-coverage` to regenerate instrumentation and reports. Remove the retired `javascript.inline` option from existing coverage configurations.

## 1.1.0 — 2026-10-17

- Added four exclusive installation modes: Luma/Cypress by default, `--hyva` for Hyvä, `--playwright` for Playwright, or both flags together.
- Each installation includes only its selected runner, browser cache, and tooling. Playwright installations omit the Cypress desktop viewer.
- `./bin/run-coverage` uses the saved runner selection and generates PHP, JavaScript, and template reports with either runner.
- Added execution coverage for regular Hyvä/Alpine directives in PHTML while preserving original PHP source lines.
- `npm run test:e2e:matrix` checks all four combinations in separate temporary installations, including elgentos Playwright guest fixtures and generated coverage reports.
- The bundled Blog supports Hyvä and provides equivalent publishing, moderation, validation, permissions, and storefront scenarios in both browser runners.
- The installation matrix verifies all seven scenarios in every mode and compares coverage for shared application code.
- Updated Magento template coverage to 1.2.0 from npm.

When updating from v1.0.14, replace the MageLens project files and rerun `./install.sh` to refresh dependencies and assets, then run `./bin/run-coverage`. The default remains Luma/Cypress. Add `--hyva`, `--playwright`, or both flags to select another combination, and repeat those flags whenever you rerun the installer.

## 1.0.14 — 2026-10-17

- Updated Cypress to 16.2.0, the Node 24 runner image to 24.22.0, PIE to 1.5.2, and PHP code coverage to 11.0.12.
- Updated Magento template coverage to 1.1.2, preserving Prototype DOM extensions on Admin pages. Retired the Admin form patch while retaining automatic recovery for interrupted older runs.
- Centralized the Cypress coverage adapter, Istanbul libraries, and nyc versions in `dependencies.yaml`, alongside the existing browser dependencies.
- Added `npm run test:e2e` for a clean temporary Magento install, real Cypress execution, and validation of all generated coverage reports, using container-only HTTPS.

When updating from v1.0.13, replace the project files and rerun `./install.sh` to install the updated dependencies and refresh published assets, then run `./bin/run-coverage`.

## 1.0.13 — 2026-10-11

- PHP, JavaScript, and HTML template coverage now excludes directories named `Test` or `Setup` from report totals.

When updating from v1.0.12, replace the project files and run `./bin/run-coverage` directly; rerunning the installer is unnecessary. The next run refreshes the coverage scope and browser instrumentation automatically.

## 1.0.12 — 2026-10-09

- Updated Magento template coverage to 1.1.1 so instrumented Underscore and Magento literal templates render safely while the execution collector is unavailable.
- Cypress reconnects restore a deleted template execution helper in retained documents.

When updating from v1.0.11, replace the project files and rerun `./install.sh` once to install the updated template coverage dependency, then use `./bin/run-coverage` as usual.

## 1.0.11 — 2026-10-06

- JavaScript coverage excludes Cypress specs and support directories from instrumentation and report totals, including stale records from older releases.
- Unvisited application JavaScript still contributes zero-hit coverage, and source integrity checks still include test files.

When updating from v1.0.10, replace the project files and run `./bin/run-coverage` directly; rerunning the installer is unnecessary. The next run rebuilds instrumentation automatically.

## 1.0.10 — 2026-10-06

- Homepage warm-up no longer times out because Magento initialization markers remain after assets have finished loading. Unfinished browser requests and RequireJS modules still block preparation and produce diagnostics.

When updating from v1.0.9, replace the project files and run `./bin/run-coverage` directly; rerunning the installer is unnecessary.

## 1.0.9 — 2026-10-06

- Reinstalling recreates PHP-FPM before Composer setup, allowing recovery from unhealthy containers and stale source mounts.
- Installation failures now show Docker health-check results and PHP socket connection errors alongside container logs.

If installation failed at PHP-FPM startup, replace the project files and rerun `./install.sh`. Existing source, Composer credentials and database volumes are retained.

## 1.0.8 — 2026-10-06

- `./bin/run-coverage` automatically warms the storefront homepage and its dynamic assets before testing, reducing first-run timeouts after installation or an asset refresh.
- Warm-up has bounded timeouts and reports unfinished requests and RequireJS modules when preparation fails.
- Coverage starts afterward in a fresh browser session, with the existing test timeouts and two-command workflow.

When updating from v1.0.7, replace the project files and run `./bin/run-coverage` directly; rerunning the installer is unnecessary.

## 1.0.7 — 2026-09-27

- Demo tests wait for asynchronous storefront and theme templates to render before checking the page.
- An interrupted Admin scenario no longer changes the storefront scenario's expected article count.

When updating from v1.0.6, replace the project files and run `./bin/run-coverage` directly; rerunning the installer is unnecessary.

## 1.0.6 — 2026-09-27

- Coverage runs reuse running services and unchanged browser instrumentation. They no longer restart containers, rewrite Magento configuration, or clear caches and static assets automatically.
- Use `--start`, `--refresh-cache`, `--refresh-assets`, and `--restart-php` when needed. Options can be combined.
- Coverage settings are explicit in `docker/php/env.php.sample` and merged into Magento's `env.php` during installation. HTML/PHTML and browser assets run without minification.
- Cypress uses your configured HTTPS domain. Source edits and selected theme changes are picked up without restarting PHP.

For an existing installation, rerun `./install.sh` once after updating, then use `./bin/run-coverage` as usual.

## 1.0.5 — 2026-09-27

- The Cypress runner recovers after an interrupted container shutdown, including during installation's SSL restart.
- Installation and coverage commands print service logs when a required container fails to start.

## 1.0.4 — 2026-09-27

- The bundled demo now selects its real storefront theme when no theme is configured. Reinstalling preserves your theme choices.
- PHP, JavaScript, and template reports follow the selected local themes and their parents. Inactive themes and `vendor` are excluded.
- Theme-specific demo content no longer prevents using another storefront theme.
- Static assets retain coverage instrumentation across repeated requests, fixing missing JavaScript and template hits.
- Magento's first-use generated classes no longer invalidate an otherwise valid PHP report.
- The storefront CSRF test now checks the rejection redirect without consuming its error message.
- Setup and patch documentation is shorter, and installation archives omit maintainer tests and release automation.
