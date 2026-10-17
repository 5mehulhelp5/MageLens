# Maintainer checks

Run the fast integration checks with `npm run test:integration`.

For a real Magento installation and browser run in a new `/tmp` directory:

```bash
MAGELENS_COMPOSER_AUTH_FILE="$HOME/.composer/auth.json" bash tests/e2e-isolated.sh
```

`npm run test:e2e` runs the same check. Docker and Magento Marketplace credentials are required; host PHP, Composer, and Node are not required for the Bash command. By default, the test reads `auth.json` from `COMPOSER_HOME`, or `$HOME/.composer` when unset. It copies credentials into a temporary Docker volume without printing them.

To reuse credentials saved by an existing MageLens installation, set `MAGELENS_COMPOSER_AUTH_VOLUME` instead, for example `MAGELENS_COMPOSER_AUTH_VOLUME=magelens_composerdata bash tests/e2e-isolated.sh`. This takes precedence over the file setting, mounts the existing volume read-only, and copies only `auth.json` into the test's own volume.

The test downloads clean Magento source, builds the versions in `dependencies.yaml`, runs the real installer and the full bundled Cypress suite, then verifies PHP, JavaScript, and template execution plus their HTML reports. It also checks the current run ID, source restoration, and fixture/collector cleanup. The installer uses `--container-only` to generate HTTPS inside Docker; it does not edit host DNS or certificate trust.

Each invocation has its own Compose project, image tags, database, credentials, and source. Ports default to **18080**, **18443**, and **16080**. Override `MAGELENS_TEST_PORT`, `MAGELENS_TEST_HTTPS_PORT`, and `MAGELENS_TEST_VIEW_PORT` when those ports are occupied or when running tests concurrently.

Reports, screenshots, and logs are retained under `.runtime/e2e/<project>/`, including `coverage/index.html`. Containers, named volumes, and temporary source are removed on success, failure, or a handled interruption. A failed Docker cleanup retains the temporary workspace and reports its location. Built images and Docker build cache remain available for subsequent runs. Forced process termination may require manual cleanup of that test's project.

This is a cold-install test of the current dependency selection. Existing-installation migration and interrupted-patch behavior also have focused integration tests in `source.test.php` and `cypress-patches.test.cjs`.
