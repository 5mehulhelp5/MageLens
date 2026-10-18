<p align="center">
  <img src="assets/magelens.svg" alt="MageLens logo" width="320">
</p>

# MageLens: Magento 2 E2E code coverage with Docker

**See which PHP, JavaScript and templates your Magento 2 end-to-end tests execute.** MageLens sets up a local Magento Open Source environment in Docker and collects PHP, JavaScript, and template coverage from a Cypress or Playwright run.

Run the installer, run the tests, and open one report to see which parts of your application executed. PHP, Composer, Node, the selected browser runner, and reporting tools run in containers.

The included [blog module](src/app/code/Application/Blog/README.md) provides an optional demonstration application with equivalent Cypress and Playwright suites for Luma and Hyvä. The badges are updated after each successful coverage run.

<!-- coverage-badges:start -->
Run `./bin/run-coverage` to generate coverage reports and badges for your project.
<!-- coverage-badges:end -->

## Quick start

Run this inside the empty directory you want to use for MageLens:

```bash
wget -qO- https://github.com/VitaliyBoyko/MageLens/archive/refs/tags/v1.3.0.tar.gz | tar -xz --strip-components=1 && ./install.sh
```

If you have already cloned or downloaded MageLens, run `./install.sh` from its project directory.

The command above installs Luma with Cypress. For another combination, append the corresponding flags to its `./install.sh` command:

| Installer command | Storefront | Browser runner |
| --- | --- | --- |
| `./install.sh` | Luma | Cypress |
| `./install.sh --hyva` | Hyvä CSP | Cypress |
| `./install.sh --playwright` | Luma | Playwright |
| `./install.sh --hyva --playwright` | Hyvä CSP | Playwright |
| `./install.sh --hyva --nocsp` | Legacy Hyvä | Cypress |
| `./install.sh --hyva --nocsp --playwright` | Legacy Hyvä | Playwright |

Each installation includes only its selected runner, browser download and runner tooling. Playwright installs have no Cypress desktop/viewer. The installer saves the selection; `./bin/run-coverage` uses it automatically. Repeat the same flags when rerunning installation; omitted flags select Luma/Cypress.

Hyvä replaces the active storefront theme. Magento's bundled Luma/Blank packages remain part of Magento; the installer does not remove core files. Hyvä is downloaded only for `--hyva`.

All six modes install their coverage dependencies from npm. `--nocsp` requires `--hyva`.

`--hyva` installs `Hyva/default-csp` and enforces its storefront script policy.
Use `--hyva --nocsp` for `Hyva/default` and existing customizations that require the
regular Alpine evaluator. The bundled Luma fallback checkout keeps its legacy script
policy; licensed Hyvä Checkout is a separate product. CSP-aware template coverage
keeps bindings and inline scripts in the template report and whole `.js` files in
the JavaScript report. Cypress preserves script CSP directives and adds its own
nonce; Playwright tests the original policy. See [Cypress CSP behavior](https://docs.cypress.io/app/references/content-security-policy).

See the [release notes](CHANGELOG.md) for changes in this version.

Then generate coverage reports:

```bash
./bin/run-coverage
```

Coverage runs reuse the running environment and automatically warm the storefront homepage before starting tests in a fresh browser. Cache cleaning, asset refreshes and restarts are [optional arguments](docs/coverage.md#run-lifecycle); use `--start` if services are stopped.

The installer asks for a test domain, defaulting to `magelens.test`, and saves it as `APPLICATION_DOMAIN` in `.env`. It downloads Magento, dependencies, and the selected runner’s browser; allow several minutes. To use an existing project, [copy its source before installing](#copy-a-complete-magento-project).

With the default domain and ports:

| Open | Location |
| --- | --- |
| Magento storefront | https://magelens.test/ |
| Magento Admin | https://magelens.test/admin/ |
| Demonstration blog | https://magelens.test/blog/ |
| Live Cypress runner | https://magelens.test:6080/ |
| Combined coverage report, after a successful test run | `coverage/index.html` on your machine |

Fresh installations create the Admin account `application` / `ApplicationOnly123456!`. Demo features and usage are documented in the [blog README](src/app/code/Application/Blog/README.md).

For Cypress installations, open the live runner before starting `./bin/run-coverage` to watch the browser. The viewer is read-only. Use your selected domain in these URLs if you changed it during setup.

## Requirements

- Docker Engine/Desktop with Compose **2.24.4+**, running Linux containers; Git, Bash, wget, and tar.
- Linux or macOS. Allocate at least **6 GB RAM** to Docker (8 GB recommended) and roughly **15 GB free disk** for the first build.
- Internet access for container images, Composer/npm dependencies, and the selected browser download.
- Magento Marketplace public/private keys for `repo.magento.com`.
- Free local ports **80** and **443**, plus **6080** for the Cypress viewer. Configure `APPLICATION_PORT`, `APPLICATION_HTTPS_PORT`, and `CYPRESS_VIEW_PORT` in `.env` to use different ports.

Installation uses Mark Shust's `bin/setup-composer-auth`. It reuses Composer credentials from the container or host, or asks for **Username** (public key) and **Password** (private key). Credentials are stored in the local `composerdata` Docker volume. To configure them separately after the PHP service starts, run `bin/setup-composer-auth`.

The installer adds the domain to your hosts file and uses Mark Shust's SSL tools to configure a trusted local HTTPS certificate. These steps request your system password when needed. The application and live viewer bind to `127.0.0.1`.

## Coverage reports

`./bin/run-coverage` runs the project’s selected browser suite and generates three reports:

| Coverage | What it measures | Local report |
| --- | --- | --- |
| PHP | Executable PHP and `.phtml` lines reached by real Magento HTTP requests, collected with PCOV | `coverage/php/index.html` |
| JavaScript | Statements in whole `.js` files, collected with Istanbul and the selected runner | `coverage/js/index.html` |
| Templates | HTML/PHTML bindings, template expressions and inline scripts, with script functions, branches and DOM presence reported separately | `coverage/templates/index.html` |

Open `coverage/index.html` directly in your browser for the combined view. Each successful full run also refreshes the four SVG badges in `coverage/badges/` and the managed badge section in this README. Reports are generated locally and are ignored by Git; the badges can be committed. Archive `coverage/` to share the browsable reports.

Coverage includes PHP executable lines, whole JavaScript files, and HTML/PHTML templates with their bindings and inline scripts under `src/app/code/`, plus selected storefront and Admin themes and their local parents under `src/app/design/`. Composer packages can be included explicitly using `vendorRoots` in [coverage.config.json](coverage.config.json). Directories named `Test`, `Setup`, `node_modules` or `tailwind`, browser specs and support directories are excluded. The theme scope is resolved from Magento on each run; unrelated inactive themes and vendor packages remain excluded. Unexecuted eligible files remain uncovered. JavaScript badges measure statements in whole `.js` files, with separate application/library reports. Inline scripts belong to template coverage, which also lists unsupported and PHP-generated script fragments. See [JavaScript coverage configuration](docs/coverage.md#javascript-coverage).

Read the [coverage guide](docs/coverage.md) for report semantics, collection details, and adding tests and fixtures.

## Magento environment

MageLens extends the Compose services from the selected [Mark Shust Docker Magento](https://github.com/markshust/docker-magento) release with local mounts and coverage tooling. That release selects PHP, nginx, MariaDB, OpenSearch, and the cache service together. A separate image supplies the selected runner; only Cypress includes the live desktop.

Magento is installed through Composer. Its modules, framework, and themes live in `src/vendor/magento/`; client modules live in `src/app/code/`. Magento runs in developer mode, generating code and static assets on demand, with page and block caches disabled for coverage collection.

The coverage configuration is explicit in [docker/php/env.php.sample](docker/php/env.php.sample). Installation merges this fragment into `src/app/etc/env.php`, preserving credentials and unrelated settings. HTML/PHTML and browser assets run without minification.

Following Mark Shust's development setup, MageLens installs [DisableTwoFactorAuth](https://github.com/markshust/magento2-module-disabletwofactorauth) as a Composer development dependency and turns off Admin 2FA for this local environment. Cypress can sign in with the Admin username and password.

## Dependency versions

Edit **[dependencies.yaml](dependencies.yaml)**, then rerun the installer with your theme and runner flags. For Luma/Cypress:

```bash
./install.sh
```

This is the single place to choose the main dependency versions:

| Component | YAML setting |
| --- | --- |
| Magento Open Source | `MAGENTO_VERSION` |
| Mark Shust Docker Magento, including its PHP and service images | `MARKSHUST_DOCKER_MAGENTO_VERSION` |
| [PCOV fork](https://github.com/VitaliyBoyko/pcov) / PIE installer | `PCOV_VERSION` / `PIE_VERSION` |
| Cypress | `CYPRESS_VERSION` |
| Playwright | `PLAYWRIGHT_VERSION` |
| Hyvä CSP / legacy theme | `HYVA_VERSION` |
| Cypress JavaScript coverage adapter | `CYPRESS_CODE_COVERAGE_VERSION` |
| Istanbul coverage data / instrumentation | `ISTANBUL_LIB_COVERAGE_VERSION` / `ISTANBUL_LIB_INSTRUMENT_VERSION` |
| Istanbul report CLI (nyc) | `NYC_VERSION` |
| [Magento template coverage](https://github.com/VitaliyBoyko/magento-template-coverage) | `TEMPLATE_COVERAGE_VERSION` |
| Cypress runner's Node and browser system dependencies | `RUNNER_IMAGE` |
| Playwright runner’s Node base image | `PLAYWRIGHT_RUNNER_IMAGE` |

Use exact release versions and keep values quoted. `RUNNER_IMAGE` is an image with a version tag. Select a Mark Shust release whose PHP and services are compatible with your Magento version.

The installer synchronizes the selected runner and shared Istanbul, nyc, and template coverage dependencies, in `package.json` and `package-lock.json`. The committed default lock selects Cypress. Installation regenerates it for Playwright when requested. Hyvä’s public package snapshot in `docker/php/hyva-packages.json` must match `HYVA_VERSION`.

To validate dependency changes, use `npm run test:e2e` for a fresh Luma/Cypress installation or `npm run test:e2e:matrix` for all six theme/runner combinations. These checks verify coverage reports in temporary environments. See [test setup and artifacts](tests/README.md). `./install.sh --container-only [domain]` supports container-only runs with self-signed HTTPS, without changing host DNS or certificate trust.

Select Playwright during installation with `./install.sh --playwright`, then use `./bin/run-coverage`. Import `test` and `expect` from `playwright/support.cjs` in project specs under `playwright/e2e/` or module `Test/Playwright/` directories. Cypress remains the default. Both runners produce PHP, JavaScript and template reports with the same source-integrity checks.

For installations created by MageLens, changing `MAGENTO_VERSION` updates Magento while preserving client modules, configuration, media, and the database. Installation stops if an update conflicts with local edits. Back up the database before upgrading; Magento setup can change its schema. Downgrades require a separate checkout and database.

For a copied project, manage Magento dependencies through its own `composer.json` and `composer.lock`. Review the demo's [Cypress patches](patches/cypress/README.md) when changing Magento versions.

## Work with the source

After installation, Magento's full source is available in **`src/`** and bind-mounted into Docker, so your IDE can browse client modules in `app/code/` and core packages in `vendor/`. Custom module and theme namespaces are tracked; Composer dependencies remain ignored.

### Copy custom modules or themes

Copy them into their normal Magento locations, for example `src/app/code/YourVendor/YourModule` or `src/app/design/frontend/YourVendor/your-theme`, then run:

```bash
./install.sh # repeat your --hyva, --nocsp and --playwright selections
./bin/run-coverage
```

The installer enables newly discovered modules and preserves explicitly disabled modules. Add Cypress tests under `cypress/e2e/` or a module's `Test/Cypress/` directory; add Playwright tests under `playwright/e2e/` or a module's `Test/Playwright/` directory. See [adding scenarios](docs/coverage.md#use-your-project) for the required Playwright coverage fixture.

Fresh installations select Luma by default and Hyvä CSP with `--hyva` (legacy Hyvä with `--hyva --nocsp`). Installation applies the selected base theme. To select a custom child theme afterward, use **Content → Design → Configuration**; the next coverage run follows your selection.

### Copy a complete Magento project

Before the first installation, place your complete project in `src/`, including `composer.json`, `composer.lock`, `bin/magento`, and `app/bootstrap.php`. Remove the bundled example module and theme if you do not want them in your project. MageLens installs dependencies from your `composer.lock` and adds the development 2FA module if it is missing. Provide credentials for any private Composer repositories your project uses.

For a fresh local database, omit the copied `app/etc/env.php`. To use existing data, import your database into the local `db` service and configure `env.php` for the local services before running `./install.sh`. The database host must be `db`.

Rerun `./install.sh` with the same theme and runner flags after module or theme changes to refresh setup and static assets. See the [coverage guide](docs/coverage.md#use-your-project) for adding scenarios and optional test fixtures.

## Everyday commands

Run these from the repository root:

```bash
./install.sh                              # install or refresh, retaining existing data
./install.sh shop.test                    # configure a different local domain
./bin/run-coverage                        # full suite, fresh reports, and badges
./bin/application-compose logs app phpfpm # inspect nginx and PHP logs
./bin/application-compose logs runner     # inspect browser runner startup
./bin/application-compose stop            # stop this project's services
bin/start                                 # start the installed environment
bin/magento cache:clean
bin/composer --version
bin/bash
bin/status
```

Installation makes Mark Shust's command-line tools available in `bin/`, connected to this project's Docker services. If you have npm on the host, `npm run cy:coverage` runs the coverage command.

The default Docker project name is `magelens`. To run multiple copies, set a unique `COMPOSE_PROJECT_NAME`, `APPLICATION_DOMAIN`, and host ports in each `.env` before installing. Keep the project name unchanged when reusing its database volumes.

Rerun `./install.sh` to resume interrupted setup or rebuild after Dockerfile changes. Existing database contents, configuration, and media are preserved.

Avoid changing application data while the tests run. See the [coverage guide](docs/coverage.md#run-lifecycle) for optional refreshes and recovery.

`./bin/application-compose down -v` deletes this project's Docker volumes, including its database and stored Composer credentials. Source files remain in `src/`. For a fresh database, back up wanted data, run that command, remove `src/app/etc/env.php`, and rerun `./install.sh`.

## Project layout

| Path | Purpose |
| --- | --- |
| `src/app/code/` | Client modules |
| `src/app/design/frontend/`, `src/app/design/adminhtml/` | Local themes |
| `src/vendor/` | Composer dependencies, including Magento core |
| `install.sh`, `compose.yaml`, `docker/` | Installation and Docker services |
| [dependencies.yaml](dependencies.yaml) | Dependency version settings |
| `bin/run-coverage` | Run the selected browser suite and generate coverage |
| `cypress/`, module `Test/Cypress/` directories | Project scenarios and browser coverage collectors |
| `playwright/`, module `Test/Playwright/` directories | Playwright scenarios and coverage fixtures |
| `coverage/` | Generated reports and badges |
| [Blog demo](src/app/code/Application/Blog/README.md) | Example application exercising all three collectors |
| [Coverage guide](docs/coverage.md) | Collector details and customization |

## FAQ

### Do I need PHP, Composer or Node installed on my host?

The application, dependencies, selected test runner and report tools run in Docker. Install the host tools listed in [requirements](#requirements), and provide Magento Marketplace credentials.

### Can I use my own Magento modules and themes?

Yes. [Copy modules or themes](#copy-custom-modules-or-themes), or [copy a complete project before installation](#copy-a-complete-magento-project), then add scenarios for the selected runner. Coverage follows the configured theme scope; vendor packages require an explicit `vendorRoots` entry.

### Why are PHP, JavaScript and template percentages different?

They measure different source operations. PHP uses executable lines, whole-file JavaScript uses Istanbul statements, and template coverage measures bindings and inline scripts with DOM presence reported separately. See the [coverage guide](docs/coverage.md); the percentages are not interchangeable.

### Is this a production deployment setup?

No. MageLens installs a local developer environment with coverage instrumentation, disabled caches and development authentication settings. Use it for testing and inspecting coverage.

## Related tools and support

- [Magento template coverage](https://github.com/VitaliyBoyko/magento-template-coverage): the standalone Cypress/Playwright template collector used here.
- [PCOV fork](https://github.com/VitaliyBoyko/pcov): PHP line coverage with native export and manifest reuse, selected in `dependencies.yaml`.
- [Magento 2 and Adobe Commerce PhpStorm plugin](https://github.com/VitaliyBoyko/magento2-phpstorm-plugin): code navigation, inspections, generators and Magento MCP tools for working with the source.

For reproducible setup or reporting problems, [open an issue](https://github.com/VitaliyBoyko/MageLens/issues) with the MageLens version, theme, runner and relevant diagnostics. See [releases](https://github.com/VitaliyBoyko/MageLens/releases) and the [changelog](CHANGELOG.md) for version changes.
