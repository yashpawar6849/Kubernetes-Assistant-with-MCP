# Sourced by the other scripts.
CLUSTER=mcp-demo
CTX=kind-$CLUSTER
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
k() { kubectl --context "$CTX" "$@"; }
