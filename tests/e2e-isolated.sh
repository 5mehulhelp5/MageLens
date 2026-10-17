#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../bin/common"
preflight
[[ $# == 0 ]] || fail 'Usage: bash tests/e2e-isolated.sh (see tests/README.md for configuration)'

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

for file in bin docker patches cypress tests assets install.sh compose.yaml dependencies.yaml package.json package-lock.json cypress.config.cjs README.md; do
    cp -a "$file" "$scratch/"
done
# Exercise the bundled demo only; existing Magento data and third-party modules
# are not fixtures. Composer downloads a clean source tree into this workspace.
mkdir -p "$scratch/src/app/code" "$scratch/src/app/design/frontend"
cp -a src/app/code/Application "$scratch/src/app/code/"
cp -a src/app/design/frontend/Application "$scratch/src/app/design/frontend/"
cd "$scratch"
printf 'COMPOSE_PROJECT_NAME=%s\nAPPLICATION_DOMAIN=%s\nAPPLICATION_PORT=%s\nAPPLICATION_HTTPS_PORT=%s\nCYPRESS_VIEW_PORT=%s\n' \
    "$project" "$APPLICATION_DOMAIN" "$APPLICATION_PORT" "$APPLICATION_HTTPS_PORT" "$CYPRESS_VIEW_PORT" > .env
# Isolate the PHP image tag too; the runner already uses the Compose project name.
sed 's|^    image: magelens-php:.*|    image: ${COMPOSE_PROJECT_NAME}-php:e2e|' compose.yaml > compose.yaml.tmp
mv compose.yaml.tmp compose.yaml
grep -qF 'image: ${COMPOSE_PROJECT_NAME}-php:e2e' compose.yaml || fail 'Could not isolate the PHP image tag.'

docker volume create --label "com.docker.compose.project=$project" \
    --label com.docker.compose.volume=composerdata "${project}_composerdata" >/dev/null
docker run --rm --user root --entrypoint sh \
    --mount "$auth_mount" \
    --mount "type=volume,source=${project}_composerdata,target=/composer" \
    "$RUNNER_IMAGE" -c 'cp "$3" /composer/auth.json && chmod 600 /composer/auth.json && chown "$1:$2" /composer/auth.json' \
    sh "$LOCAL_UID" "$LOCAL_GID" "$auth_path"

(
    ./install.sh --container-only "$APPLICATION_DOMAIN"
    ./bin/application-compose exec -T runner node tests/dependencies.test.cjs
    ./bin/run-coverage
    ./bin/application-compose exec -T runner node tests/verify-demo.cjs
    ./bin/application-compose exec -T runner node tests/verify-e2e.cjs
) 2>&1 | tee "$artifacts/run.log"
printf 'PASS: isolated installation, Cypress suite, and PHP/JavaScript/template coverage.\n'
