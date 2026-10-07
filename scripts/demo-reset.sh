#!/usr/bin/env bash
# Put the cluster back into the broken state (~30s). Keeps the ServiceAccount token valid,
# so the MCP server keeps working without a restart.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
k -n shop delete svc db --ignore-not-found >/dev/null
k -n shop delete deploy checkout --ignore-not-found --wait=true >/dev/null
k -n shop delete events --all >/dev/null
k apply -f "$ROOT/k8s/apps.yaml" >/dev/null
: > "$ROOT/audit.log"
for _ in $(seq 1 40); do
  k -n shop get pods -l app=checkout 2>/dev/null | grep -q CrashLoopBackOff && break; sleep 2
done
k -n shop get pods
