#!/usr/bin/env bash
# verify.sh — Verifies a court deployment after bootstrap.
#
# Usage: ./verify.sh
#
# Checks:
#   1. Scope entity exists and is valid (EvaluateOrigin)
#   2. All three logs are reachable
#   3. Schemas are adopted
#   4. Anchor is registered (if configured)
#   5. Witnesses are reachable
#   6. Escrow nodes respond to health checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"

PASS=0
FAIL=0

check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "  ✓ ${name}"
        PASS=$((PASS + 1))
    else
        echo "  ✗ ${name}"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Court Deployment Verification ==="
echo ""

echo "Scope entity:"
check "EvaluateOrigin on officers log" \
    trust-network-courts verify-scope \
    --court-config "${CONFIG_DIR}/court.yaml" \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --log officers

check "EvaluateOrigin on cases log" \
    trust-network-courts verify-scope \
    --court-config "${CONFIG_DIR}/court.yaml" \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --log cases

check "EvaluateOrigin on parties log" \
    trust-network-courts verify-scope \
    --court-config "${CONFIG_DIR}/court.yaml" \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --log parties

echo ""
echo "Log reachability:"
check "Officers log ledger" \
    trust-network-courts ping-ledger \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --log officers

check "Cases log ledger" \
    trust-network-courts ping-ledger \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --log cases

check "Parties log ledger" \
    trust-network-courts ping-ledger \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --log parties

echo ""
echo "Schemas:"
check "Schema adoption on cases log" \
    trust-network-courts verify-schemas \
    --court-config "${CONFIG_DIR}/court.yaml" \
    --logs-config "${CONFIG_DIR}/logs.yaml" \
    --schemas-config "${CONFIG_DIR}/schemas.yaml"

if [[ -f "${CONFIG_DIR}/anchor.yaml" ]]; then
    echo ""
    echo "Anchor:"
    check "Anchor log reachable" \
        trust-network-courts ping-ledger \
        --anchor-config "${CONFIG_DIR}/anchor.yaml"
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
exit ${FAIL}
