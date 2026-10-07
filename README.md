# Kubernetes Assistant with MCP

A small, readable [Model Context Protocol](https://modelcontextprotocol.io) server that lets an AI assistant
diagnose a broken application on a local Kubernetes cluster, with guardrails you can explain and audit.

Companion demo for the talk **"Build Your Own AI Kubernetes Assistant with MCP"**.

```
MCP host (Claude Code / Claude Desktop)
        │  stdio
        ▼
server/server.py ── ServiceAccount token ──▶ kube-apiserver  (RBAC has the final say)
        │
        └── audit.log  (append-only JSON lines)
```

## Features

| Tool | Access | Guardrails |
|---|---|---|
| `list_pods(namespace)` | read-only | name, phase, status, restart count |
| `get_pod_logs(pod, namespace, tail=50)` | read-only | hard cap of 200 lines enforced server-side; log text treated as untrusted data |
| `get_events(namespace)` | read-only | 20 most recent Warning events |
| `restart_deployment(name, namespace)` | **destructive** | namespace allow-list `{shop, staging}`, restart only, server-side dry-run preview, host approval prompt |

The `diagnose_pod` prompt is a runbook: inspect pods, events and logs, then report root cause, evidence and a
proposed fix, and ask before any restart.

## Defence in depth

1. **Server guardrails**: input validation, namespace allow-list, log-line cap, a single write tool that can only restart.
2. **Kubernetes RBAC** ([k8s/rbac.yaml](k8s/rbac.yaml)): the server connects as a dedicated ServiceAccount that can
   read pods, pod logs and events, and `patch` deployments in `shop` only. No secrets, no `pods/exec`, no delete.
   Even a bug in the server cannot exceed these permissions. `scripts/prove-rbac.sh` demonstrates it with `kubectl auth can-i`.
3. **Audit trail**: every call, including rejections and errors, is appended to `audit.log`.

## Requirements

Docker, [kind](https://kind.sigs.k8s.io), kubectl, Python 3.10+, [uv](https://docs.astral.sh/uv/).
`scripts/preflight.sh` checks them (and installs missing ones via Homebrew on macOS).

## Quick start

```bash
./scripts/preflight.sh          # verify tooling
./scripts/setup.sh              # kind cluster, namespaces, demo apps, RBAC, ServiceAccount kubeconfig (idempotent)
uv run python tests/client.py   # exercise every tool and guardrail over stdio
./scripts/register-claude.sh    # register the server with Claude Code (project scope)
```

Then start `claude` in this directory and approve the `k8s-assistant` project server once.

## The demo scenario

Namespace `shop` runs `cart` and `orders-db` (healthy) and `checkout`, which crash-loops because it resolves the wrong
database host (`connection refused: db:5432`). `scripts/fix-db.sh` creates the missing `db` Service, after which a
restart recovers `checkout`. The full live script is in [DEMO.md](DEMO.md).

## Scripts

| Script | Purpose |
|---|---|
| `setup.sh` / `teardown.sh` | create / delete the cluster |
| `fix-db.sh` | create Service `db` (the fix) |
| `demo-reset.sh` | return to the broken state in under a minute |
| `make-kubeconfig.sh` | kubeconfig for the `mcp-assistant` ServiceAccount (short-lived token, git-ignored) |
| `prove-rbac.sh` | show allowed vs denied actions |
| `demo-dry-run.sh` | replay the demo with typing delays (fallback if the live run fails) |
| `record.sh` | record the replay to `recordings/` |
| `show-audit.sh` | pretty-print the audit log |

Terminal setup for screen recording: [scripts/mac-terminal-setup.md](scripts/mac-terminal-setup.md).

## Using Claude Desktop

Merge this entry into `mcpServers` in `~/Library/Application Support/Claude/claude_desktop_config.json`
(do not replace the file). Use absolute paths: `which uv` for the command and `pwd` for the project directory.

```json
{
  "mcpServers": {
    "k8s-assistant": {
      "command": "/opt/homebrew/bin/uv",
      "args": ["--directory", "/ABS/PATH/k8s-mcp-demo", "run", "python", "server/server.py"],
      "env": { "K8S_MCP_KUBECONFIG": "/ABS/PATH/k8s-mcp-demo/kubeconfig/mcp-assistant.kubeconfig" }
    }
  }
}
```

## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `K8S_MCP_KUBECONFIG` | `kubeconfig/mcp-assistant.kubeconfig` | kubeconfig the server uses |
| `K8S_MCP_AUDIT_LOG` | `audit.log` | audit log path |

Dependencies are pinned in `pyproject.toml` / `uv.lock` (`mcp==1.30.0`, `kubernetes==36.0.3`).

## Security notes

- No secrets are committed; `kubeconfig/` holds a short-lived token and is git-ignored.
- `staging` is allowed by the server but denied by RBAC. That mismatch is deliberate, to show RBAC is the real boundary.
- This is a demo for a local kind cluster. Review the permissions before pointing it at anything shared.

## License

Apache License 2.0. See [LICENSE](LICENSE).
