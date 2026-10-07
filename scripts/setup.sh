#!/usr/bin/env bash
# Idempotent: safe to run any number of times.
set -euo pipefail
source "$(dirname "$0")/_common.sh"

if kind get clusters | grep -qx "$CLUSTER"; then
  echo "==> kind cluster '$CLUSTER' already exists"
else
  echo "==> creating kind cluster '$CLUSTER'"
  kind create cluster --name "$CLUSTER" --image kindest/node:v1.30.0 --wait 120s
fi

for ns in shop staging; do
  k create namespace "$ns" --dry-run=client -o yaml | k apply -f - >/dev/null
done

echo "==> deploying apps and RBAC"
k apply -f "$ROOT/k8s/apps.yaml" -f "$ROOT/k8s/rbac.yaml" >/dev/null
for d in cart orders-db; do k -n shop rollout status deploy/$d --timeout=180s >/dev/null; done

"$ROOT/scripts/make-kubeconfig.sh"

echo "==> waiting for checkout to start crash-looping (expected)"
for _ in $(seq 1 40); do
  k -n shop get pods -l app=checkout 2>/dev/null | grep -q CrashLoopBackOff && break; sleep 3
done
echo; k -n shop get pods
