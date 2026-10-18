#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../bin/common"
preflight
[[ $# == 0 ]] || fail 'Usage: bash tests/e2e-isolated.sh (see tests/README.md for configuration)'
theme=${MAGELENS_E2E_THEME:-luma}
runner=${MAGELENS_E2E_RUNNER:-cypress}
[[ "$theme" == luma || "$theme" == hyva || "$theme" == hyva-legacy ]] || fail 'MAGELENS_E2E_THEME must be luma, hyva or hyva-legacy.'
[[ "$runner" == cypress || "$runner" == playwright ]] || fail 'MAGELENS_E2E_RUNNER must be cypress or playwright.'
install_options=()
[[ "$theme" != hyva* ]] || install_options+=(--hyva)
[[ "$theme" != hyva-legacy ]] || install_options+=(--nocsp)
[[ "$runner" != playwright ]] || install_options+=(--playwright)

if [[ -n "${MAGELENS_COMPOSER_AUTH_VOLUME:-}" ]]; then
    docker volume inspect "$MAGELENS_COMPOSER_AUTH_VOLUME" >/dev/null
    auth_mount="type=volume,source=$MAGELENS_COMPOSER_AUTH_VOLUME,target=/auth-source,readonly"
    auth_path=/auth-source/auth.json
else
    auth=${MAGELENS_COMPOSER_AUTH_FILE:-${COMPOSER_HOME:-$HOME/.composer}/auth.json}
    [[ -r "$auth" ]] || fail 'Set MAGELENS_COMPOSER_AUTH_FILE to a readable auth.json, or MAGELENS_COMPOSER_AUTH_VOLUME to an existing Composer credentials volume.'
    auth=$(cd "$(dirname "$auth")" && pwd)/$(basename "$auth")
    auth_mount="type=bind,source=$auth,target=/auth.json,readonly"
    auth_path=/auth.json
fi
original_root=$ROOT
scratch=$(mktemp -d /tmp/magelens-e2e.XXXXXX)
project="magelens-e2e-$(basename "$scratch" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
artifacts="$original_root/.runtime/e2e/$project"
mkdir -p "$artifacts"
# Override inherited Compose settings so creation and cleanup target only this run.
export COMPOSE_PROJECT_NAME="$project" APPLICATION_DOMAIN="$project.test"
export APPLICATION_PORT=${MAGELENS_TEST_PORT:-18080}
export APPLICATION_HTTPS_PORT=${MAGELENS_TEST_HTTPS_PORT:-18443}
export CYPRESS_VIEW_PORT=${MAGELENS_TEST_VIEW_PORT:-16080}

cleanup() {
    local result=$?
    trap - EXIT
    if [[ -d "$scratch/coverage" ]]; then
        cp -a "$scratch/coverage" "$artifacts/" || result=1
    fi
    if [[ -d "$scratch/cypress/screenshots" ]]; then
        cp -a "$scratch/cypress/screenshots" "$artifacts/" || result=1
    fi
    if (( result != 0 )) && [[ "${MAGELENS_E2E_KEEP_ON_FAILURE:-0}" == 1 ]]; then
        printf 'Failed E2E workspace retained for debugging: %s\n' "$scratch" >&2
        printf 'Clean up with: cd %q && ./bin/application-compose --profile "*" down --volumes --remove-orphans\n' "$scratch" >&2
        exit "$result"
    fi
    if [[ -f "$scratch/.runtime/docker-magento/compose/compose.yaml" ]]; then
        (cd "$scratch" && ./bin/application-compose logs --no-color) > "$artifacts/services.log" 2>&1 || true
        # Include the install-only workspace profile so its legacy appdata volume
        # is removed even though the one-off workspace container has exited.
        if ! (cd "$scratch" && ./bin/application-compose --profile '*' down --volumes --remove-orphans); then
            printf 'Cleanup failed; temporary workspace retained at %s\n' "$scratch" >&2
            exit 1
        fi
    fi
    # The credentials volume can exist even when installation fails before Compose starts.
    if docker volume inspect "${project}_composerdata" >/dev/null 2>&1; then
        docker volume rm "${project}_composerdata" >/dev/null || result=1
    fi
    rm -rf "$scratch"
    printf 'E2E artifacts: %s\n' "$artifacts"
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for file in bin docker patches cypress playwright tests assets install.sh .dockerignore compose.yaml dependencies.yaml coverage.config.json package.json package-lock.json cypress.config.cjs playwright.config.cjs README.md; do
    cp -a "$file" "$scratch/"
done
mkdir -p "$scratch/docker/php/e2e"
cp tests/fixtures/compatibility/*.php "$scratch/docker/php/e2e/"
cp tests/php-report.test.php "$scratch/docker/php/e2e/"
# Exercise the bundled demo only; existing Magento data and third-party modules
# are not fixtures. Composer downloads a clean source tree into this workspace.
mkdir -p "$scratch/src/app/code" "$scratch/src/app/design/frontend"
cp -a src/app/code/Application "$scratch/src/app/code/"
cp -a src/app/design/frontend/Application "$scratch/src/app/design/frontend/"
mkdir -p "$scratch/src/app/code/MageLens"
cp -a tests/fixtures/compatibility/module "$scratch/src/app/code/MageLens/Compatibility"
if [[ -n "${MAGELENS_TEMPLATE_COVERAGE_PACKAGE:-}" ]]; then
    mkdir -p "$scratch/.runtime"
    cp "$MAGELENS_TEMPLATE_COVERAGE_PACKAGE" "$scratch/.runtime/template-coverage.tgz"
fi
cd "$scratch"
printf 'COMPOSE_PROJECT_NAME=%s\nAPPLICATION_DOMAIN=%s\nAPPLICATION_PORT=%s\nAPPLICATION_HTTPS_PORT=%s\nCYPRESS_VIEW_PORT=%s\n' \
    "$project" "$APPLICATION_DOMAIN" "$APPLICATION_PORT" "$APPLICATION_HTTPS_PORT" "$CYPRESS_VIEW_PORT" > .env
# Isolate the PHP image tag too; the runner already uses the Compose project name.
sed 's|^    image: magelens-php:.*|    image: ${COMPOSE_PROJECT_NAME}-php:e2e|' compose.yaml > compose.yaml.tmp
mv compose.yaml.tmp compose.yaml
grep -qF 'image: ${COMPOSE_PROJECT_NAME}-php:e2e' compose.yaml || fail 'Could not isolate the PHP image tag.'

docker volume create --label "com.docker.compose.project=$project" \
    --label com.docker.compose.volume=composerdata "${project}_composerdata" >/dev/null
bootstrap_image=$RUNNER_IMAGE
[[ "$runner" != playwright ]] || bootstrap_image=$PLAYWRIGHT_RUNNER_IMAGE
docker run --rm --user root --entrypoint sh \
    --mount "$auth_mount" \
    --mount "type=volume,source=${project}_composerdata,target=/composer" \
    "$bootstrap_image" -c 'cp "$3" /composer/auth.json && chmod 600 /composer/auth.json && chown "$1:$2" /composer/auth.json' \
    sh "$LOCAL_UID" "$LOCAL_GID" "$auth_path"

(
    ./install.sh --container-only "${install_options[@]}" "$APPLICATION_DOMAIN"
    ./bin/application-compose exec -T runner node tests/verify-installation.cjs "$theme" "$runner"
    ./bin/application-compose exec -T phpfpm php /application/docker/php/e2e/verify-installation.php "$theme"
    ./bin/application-compose exec -T runner node tests/dependencies.test.cjs
    ./bin/application-compose exec -T -e MAGELENS_REPORT_DATA=/application/docker/php/report-data.php phpfpm \
        php -d pcov.directory=/tmp -d pcov.exclude= /application/docker/php/e2e/php-report.test.php
    if [[ "$runner" == playwright ]]; then
        ./bin/application-compose exec -T runner npm install --no-save --package-lock=false --ignore-scripts --no-audit --no-fund @elgentos/magento2-playwright@7.1.0
        ./bin/application-compose exec -T runner node tests/setup-compatibility.cjs
    fi
    ./bin/application-compose exec -T phpfpm bash /application/docker/php/refresh-assets.sh
    # The installer selection must drive coverage without an extra runner flag.
    ./bin/run-coverage
    ./bin/application-compose exec -T phpfpm php /application/docker/php/e2e/verify-php-report.php
    ./bin/application-compose exec -T runner node tests/verify-demo.cjs
    ./bin/application-compose exec -T runner node tests/verify-scenarios.cjs
    ./bin/application-compose exec -T runner node tests/verify-e2e.cjs
    ./bin/application-compose exec -T runner node tests/verify-compatibility.cjs "$theme"
    mkdir -p "$artifacts/$runner"
    cp -a coverage "$artifacts/$runner/"
    if [[ -n "${MAGELENS_E2E_RESULT_FILE:-}" ]]; then printf '%s\n' "$artifacts/$runner/coverage" > "$MAGELENS_E2E_RESULT_FILE"; fi
) 2>&1 | tee "$artifacts/run.log"
printf 'PASS: isolated %s installation, %s, and PHP/JavaScript/template coverage.\n' "$theme" "$runner"
