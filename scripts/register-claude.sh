#!/usr/bin/env bash
# Registers the MCP server with Claude Code (project scope) using absolute paths for THIS machine.
set -euo pipefail
cd "$(dirname "$0")/.."
claude mcp remove k8s-assistant --scope project >/dev/null 2>&1 || true
claude mcp add k8s-assistant --scope project \
  --env K8S_MCP_KUBECONFIG="$PWD/kubeconfig/mcp-assistant.kubeconfig" \
  -- "$(command -v uv)" --directory "$PWD" run python server/server.py
claude mcp list | grep k8s-assistant
echo "First time only: run 'claude' in this folder and approve the project MCP server."
