# Live demo script (about 6 minutes)

**Before you go on stage** (once): `./scripts/setup.sh`, `./scripts/register-claude.sh`, run `claude` in this
folder and approve the `k8s-assistant` server. Check with `/mcp` that it is connected.
**Before every run:** `./scripts/demo-reset.sh` (about 45 s), then open the `claude` session.

Left pane = shell. Right pane (or second window) = `claude`.

---

### 1. Show the broken app (30 s)
```
kubectl get pods -n shop
```
> "cart and orders-db are fine. checkout is in CrashLoopBackOff. Normally I'd start grepping logs."

### 2. Ask the assistant (90 s)
Prompt:
```
Why is checkout crashing in shop?
```
Expect three tool calls: `list_pods`, `get_events`, `get_pod_logs`. Root cause: it cannot connect to the
database (`connection refused: db:5432`, there is no Service named `db`, only `orders-db`).
> Point at the tool names and at the read-only badge. "It only read. Nothing changed yet."

(Optional: type `/mcp` then pick the `diagnose_pod` prompt to show the runbook.)

Apply the proposed fix yourself, in the shell, so the audience sees who has the power:
```
./scripts/fix-db.sh
```

### 3. Restart with approval (60 s)
Prompt:
```
Restart the checkout deployment in shop
```
The approval dialog for `restart_deployment` appears (it is marked destructive). Show the arguments, **approve**.
> Point at the dry-run preview in the response.

### 4. Recovered (20 s)
```
kubectl get pods -n shop
```
checkout is `1/1 Running`. (Wait 10 s after approving; or `kubectl get pods -n shop -w`.)

### 5. Guardrail (45 s)
Prompt:
```
Restart the checkout deployment in namespace prod
```
Rejected by the server's allow-list before any API call: `namespace 'prod' is not allowed`.
> "The model can ask. The code says no."

### 6. RBAC, the real boundary (60 s)
```
./scripts/prove-rbac.sh
```
> "Even if my Python had a bug, the API server would still refuse secrets, exec, delete, and anything outside shop."

### 7. Audit trail (30 s)
```
tail -n 5 audit.log        # raw JSON lines
./scripts/show-audit.sh 5   # same, one tidy line per call
```
> "Every call, including the rejected one, is recorded."

---

## If it goes wrong
* Replay everything with typing effects: `./scripts/demo-dry-run.sh` (real commands, scripted narration).
* Pods stuck? `./scripts/demo-reset.sh`.
* `k8s-assistant` shows as failed in `/mcp`? Token expired (72 h): `./scripts/make-kubeconfig.sh`, restart `claude`.
* Pre-recorded video: `recordings/demo.mp4` (1080p; plus `demo.cast`: `asciinema play recordings/demo.cast`).
