#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
result=0
for theme in luma hyva; do
    for runner in cypress playwright; do
        if ! MAGELENS_E2E_THEME="$theme" MAGELENS_E2E_RUNNER="$runner" bash tests/e2e-isolated.sh; then result=1; fi
    done
done
exit "$result"
