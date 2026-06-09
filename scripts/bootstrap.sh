#!/usr/bin/env bash
#
# bootstrap.sh — bring up a FULL trust-network-courts network from a clean clone.
#
# One command provisions everything locally via the Go e2e runner (cmd/e2e):
#   1. builds the JN-owned images from deployment/local/Dockerfile.* (NOT pulled);
#   2. pulls the baseproof/tooling fleet (ledger/witness/auditor) + postgres + seaweedfs;
#   3. mints the TLS certs, signer/auditor keys, and the network bootstrap;
#   4. brings up  witnesses → ledger → auditors → JN enforcer → aggregator.
# The stack is persisted; inspect or tear it down with `./bin/e2e status|wipe`.
#
# Usage:
#   scripts/bootstrap.sh [preset] [extra `e2e up` flags...]
#     preset : single | federation | mega        (default: single)
#   examples:
#     scripts/bootstrap.sh                       # one network
#     scripts/bootstrap.sh federation            # federated multi-network
#     scripts/bootstrap.sh federation --trace    # + leaf-loss validation signals
#
# Requires on the host (nothing else is needed — the repo carries the rest):
#   • Go 1.25+                — to build the runner (and the JN images, inside Docker)
#   • a running Docker daemon — builds JN images, runs every container, mints fixtures
#   • network access to       docker.io (postgres, seaweedfs) and
#                             ghcr.io/baseproof/tooling/* (the ledger fleet).
#                             Run `docker login ghcr.io` first if those packages
#                             are private to you.
#
set -euo pipefail

cd "$(dirname "$0")/.."

preset="${1:-single}"
[ $# -gt 0 ] && shift || true   # any remaining args pass through to `e2e up`

say() { printf '\n== %s ==\n' "$1"; }

say "prerequisites"
command -v go     >/dev/null 2>&1 || { echo "✗ Go toolchain not found (need go 1.25+)"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "✗ docker CLI not found"; exit 1; }
docker info       >/dev/null 2>&1 || { echo "✗ Docker daemon not reachable — start Docker and retry"; exit 1; }
echo "✔ $(go version | awk '{print $1, $3}'); docker $(docker version -f '{{.Server.Version}}' 2>/dev/null || echo '?')"

say "build the e2e runner (./bin/e2e)"
make e2e

say "bootstrap the '${preset}' network (builds JN images, pulls the fleet, mints fixtures)"
./bin/e2e up "${preset}" "$@"

say "health"
./bin/e2e status

cat <<EOF

✔ network '${preset}' is up. Next:
    ./bin/e2e status     # health: committed / cosigned / backlog
    ./bin/e2e run        # run the test recipes against it
    ./bin/e2e wipe       # tear it down + drop state
EOF
