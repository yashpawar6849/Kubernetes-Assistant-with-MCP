#!/usr/bin/env bash
# Builds a kubeconfig for the mcp-assistant ServiceAccount (short-lived token, 72h).
# The file is git-ignored; nothing secret is committed.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
OUT="$ROOT/kubeconfig/mcp-assistant.kubeconfig"
mkdir -p "$ROOT/kubeconfig"

TOKEN=$(k -n shop create token mcp-assistant --duration 72h)
SERVER=$(k config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')
CA=$(k config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

cat > "$OUT" <<Y
apiVersion: v1
kind: Config
clusters:
- name: $CLUSTER
  cluster: {server: $SERVER, certificate-authority-data: $CA}
users:
- name: mcp-assistant
  user: {token: $TOKEN}
contexts:
- name: mcp-assistant@$CLUSTER
  context: {cluster: $CLUSTER, user: mcp-assistant, namespace: shop}
current-context: mcp-assistant@$CLUSTER
Y
chmod 600 "$OUT"
echo "==> wrote $OUT"
