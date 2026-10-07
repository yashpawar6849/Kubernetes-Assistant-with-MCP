#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
kind delete cluster --name "$CLUSTER"
rm -f "$ROOT/kubeconfig/mcp-assistant.kubeconfig"
