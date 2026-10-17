# MageLens coverage

Run `./bin/run-coverage` from the repository root, then open `coverage/index.html`. The command runs the full suite for the runner selected during installation and generates PHP, JavaScript, and HTML template reports. See the [quick start](../README.md#quick-start) for installation.

## Coverage scope

Coverage includes supported files in:

- `src/app/code/`
- The selected frontend and Admin themes under `src/app/design/`, including their local parent themes.

PHP and `.phtml` files appear in the PHP report, application `.js` files in the JavaScript report, and `.html` files plus supported Alpine directives in `.phtml` files in the template report. Directories named `Test` or `Setup` are excluded from collection, instrumentation, and all coverage reports. Cypress and Playwright specs (`*.cy.js`, `*.spec.js`, `*.spec.ts`) and their support directories are also excluded from instrumentation and JavaScript reports. Unexecuted application files within this scope remain uncovered. Unrelated inactive themes and Composer packages under `src/vendor/` are excluded. Each run resolves the configured themes for active stores and Admin before instrumenting sources, so changing the selected theme updates all three reports.

Coverage runs use disposable source copies and verify that your originals remain unchanged. Symlinked source files and directories are unsupported.

## Run lifecycle

Each run replaces previous reports and starts fresh execution counters. Unchanged browser instrumentation is reused; source edits update the disposable runtime copies. Run installation and coverage commands one at a time.

After instrumentation, compatibility patches and fixture preparation, the command warms the storefront homepage using the installed runner in a separate browser. This prepares shared [static assets generated on demand in developer mode](https://experienceleague.adobe.com/en/docs/commerce-operations/configuration-guide/cli/static-view/static-view-file-deployment).

Warm-up allows up to three minutes per navigation/readiness check and ten minutes overall, with up to ten seconds to terminate the browser. It waits for the document load, enabled RequireJS modules (including `text!` templates), browser requests and a one-second quiet interval. Remaining `data-mage-init` and `text/x-magento-init` declaration markers are recorded for diagnostics; their presence does not block readiness. Coverage collection begins after warm-up succeeds, in a fresh browser session with the existing test timeouts. Warm-up execution contributes no PHP, JavaScript or template hits to the reports.

If preparation fails, the run stops and cleans its fixtures and patches before starting collection or tests. Inspect `coverage/warmup-results.json`, `coverage/warmup-diagnostics.json` and `coverage/warmup-screenshots/`. Normal Cypress failures include unfinished request URLs, their elapsed time, unresolved RequireJS modules and HTTP errors. An overall timeout may terminate Cypress before it writes final diagnostics; the terminal retains the last Cypress error/output.

The default command uses the running services and the configured HTTPS domain. It does not restart services, change Magento configuration, or clear caches and static assets. Avoid changing application data while the tests run.

Optional refreshes can be combined:

| Option | Use when |
| --- | --- |
| `--start` | Application services are stopped |
| `--refresh-cache` | Layout or configuration changes need a cache clean |
| `--refresh-assets` | Static assets need rebuilding, for example after adding a theme override or moving a file; also cleans caches |
| `--restart-php` | PHP-FPM needs restarting |

For example: `./bin/run-coverage --start --refresh-assets`.

Installation merges [docker/php/env.php.sample](../docker/php/env.php.sample) into `src/app/etc/env.php`, preserving credentials, theme selections and unrelated settings. The fragment enables developer mode, disables full-page/block output caching and HTML/PHTML, JavaScript and CSS minification, and sets local URLs and Admin defaults. These settings also apply at website and store scope. HTML assets pass through unchanged; PHTML executes directly. CSS/LESS compilation remains available for themes. Edit the fragment and rerun installation to change these defaults.

The combined report and badges are published after all tests pass and the coverage records and source checks succeed. Skipped or pending tests prevent publication. The README badge section is marked pending when collection starts.

If a process is forcibly terminated, check for active installation or coverage processes before removing `.runtime/workflow.lock` and rerunning the command. For the demo's patch recovery command, see [Cypress patch notes](../patches/cypress/README.md).

## Watch a test run

For Cypress installations, open `https://magelens.test:6080/`, then start `./bin/run-coverage` in your terminal. The viewer shows the Cypress browser as tests execute. Between runs, it displays a waiting screen. Viewing is read-only, so watching a run does not send mouse or keyboard input to the tests. Playwright installations run headlessly and do not install or expose this viewer; failure traces and screenshots are saved under `coverage/playwright-artifacts/`.

Use your configured `APPLICATION_DOMAIN` and `CYPRESS_VIEW_PORT` if they differ from the defaults. The viewer starts with the environment; use `--start` if it is stopped.

Both runners fail tests on uncaught application errors. Cypress disables cross-document view-transition animations inside its test frame so navigation between Hyvä and Admin remains reliable. This does not change normal storefront browsing; animation behavior is outside the bundled acceptance checks.

## PHP coverage

[PCOV](https://github.com/VitaliyBoyko/pcov) collects PHP execution from Magento HTTP requests made during the current browser run. CLI execution is outside the collection scope.

The PHP report measures executable lines. Unvisited files are included through static analysis with zero hits. `phpunit/php-code-coverage` generates HTML and Clover reports.

Every run records fresh execution. Cached collection metadata is refreshed automatically when source, configuration, or dependencies change.

## JavaScript coverage

`istanbul-lib-instrument` adds execution counters to application `.js` files under the source directories, excluding browser specs and support directories. Cypress collects counters through `@cypress/code-coverage`; Playwright collects snapshots from each browser context. Both use nyc to generate reports. Cypress records from older instrumentation are also removed before reporting.

Files that are never loaded retain zero-hit counters from instrumentation. The report combines these with execution observed during the current suite.

## HTML template coverage

[@vitaliiboiko/magento-template-coverage](https://github.com/VitaliyBoyko/magento-template-coverage) measures `.html` templates and supported Alpine directives in `.phtml` files. The report contains directory totals and per-file source views.

Hyvä coverage supports the regular Alpine 3 evaluator. The restricted Alpine CSP evaluator, inline JavaScript bodies in PHTML, and directives generated entirely by PHP are outside template execution coverage.

The template badge measures **executable template lines**: starting lines of bindings and expressions that execute. Static markup has no execution denominator. A Knockout event binding hit records binding evaluation; it does not prove that its handler ran.

**DOM presence** is reported separately. Hidden elements count as present, while fetching HTML alone does not. Templates with unsupported execution syntax remain visible with an explanation of the available DOM coverage.

## Use your project

For a Cypress installation, follow the [source setup instructions](../README.md#work-with-the-source), then add scenarios in `cypress/e2e/**/*.cy.js` or a module's `Test/Cypress/**/*.cy.js`. All matching scenarios run with `./bin/run-coverage`.

For Playwright, install with `./install.sh --playwright` (add `--hyva` for Hyvä), then add specs in `playwright/e2e/**/*.spec.{js,ts}` or a module’s `Test/Playwright/` directory. Import `test` and `expect` from the project’s `playwright/support.cjs` so all three collectors run. `./bin/run-coverage` reads the saved runner selection.

Rerun `./install.sh` with the same theme/runner flags after adding modules or themes, changing setup code, or updating dependencies. Selecting another installed theme updates the next run's scope automatically.

Modules can provide optional fixture hooks in `Test/MageLens/hooks.php`:

| Action | When it runs | Expected output |
| --- | --- | --- |
| `before` | Before fixture preparation, with services running | Optional diagnostic output |
| `prepare` | Before browser warm-up and coverage collection | One JSON value on stdout; diagnostics on stderr |
| `cleanup` | When the run exits; also before preparation if a previous run was interrupted | Optional diagnostic output; safe to repeat |

Cypress receives each module's `prepare` result through `Cypress.expose('projectFixtures')[moduleName]`. Playwright tests can read the same data from `coverage/project-fixtures.json`. The [blog hooks](../src/app/code/Application/Blog/Test/MageLens/hooks.php) provide an example of fixture creation and cleanup.

## Reports and artifacts

Detailed HTML reports live in `coverage/php/`, `coverage/js/`, and `coverage/templates/`. `coverage/summary.json` records the run ID, generation time, and displayed metrics.

For collection details, inspect PHP records under `coverage/raw/php/<run-id>/`, template observations under `coverage/raw/templates/`, and JavaScript counters in `.nyc_output/out.json`. Each run creates fresh execution records.

Reports and raw artifacts are ignored by Git. The SVGs in `coverage/badges/` can be committed with the README. To share browsable reports, copy the entire `coverage/` directory so relative links continue to work.
