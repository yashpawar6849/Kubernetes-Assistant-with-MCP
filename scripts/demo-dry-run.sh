#!/usr/bin/env bash
# Fallback for stage: replays the whole demo with realistic typing.
# Commands and MCP tool calls are REAL (cluster + server). Only the model's narration is scripted.
#   ./scripts/demo-dry-run.sh            # normal speed
#   SPEED=0 ./scripts/demo-dry-run.sh    # no typing delay (rehearsal / CI)
#   NO_RESET=1 ...                       # skip the cluster reset (already broken)
set -uo pipefail
source "$(dirname "$0")/_common.sh"
cd "$ROOT"
SPEED=${SPEED:-1}
B=$'\e[1m'; D=$'\e[2m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; R=$'\e[31m'; N=$'\e[0m'

type_out() {  # text typed char by char with slight jitter
  local s=$1 i
  for ((i = 0; i < ${#s}; i++)); do
    printf '%s' "${s:i:1}"
    [ "$SPEED" = 0 ] || sleep "0.0$((RANDOM % 5 + 3))"
  done
}
pause() { [ "$SPEED" = 0 ] || sleep "$1"; }
shell()  { printf '%s❯%s ' "$G" "$N"; type_out "$1"; echo; pause 0.4; eval "$1"; echo; pause 1.5; }
ask()    { printf '%s>%s ' "$C" "$N"; type_out "$1"; echo; pause 0.8; }
tool()   { printf '%s● k8s-assistant%s%s › %s(%s)%s\n' "$Y" "$N" "$D" "$1" "$2" "$N"; }
say()    { printf '%s\n' "$1" | fold -s -w 88 | sed 's/^/  /'; pause 1; }
call()   { uv run python scripts/call-tool.py "$1" "$2" 2>/dev/null | cut -c1-100 | head -${3:-12} | sed "s/^/  $D│$N /"; pause 1; }

export TERM=${TERM:-xterm-256color}
section() { pause 1.5; clear; echo "${B}$1${N}"; echo; pause 1; }
if [ -z "${NO_RESET:-}" ]; then ./scripts/demo-reset.sh >/dev/null 2>&1; fi

section "1. The broken app"
shell "kubectl get pods -n shop"

section "2. Ask the assistant"
ask "Why is checkout crashing in shop?"
POD=$(k -n shop get pods -l app=checkout -o jsonpath='{.items[0].metadata.name}')
tool list_pods "namespace: shop";  call list_pods '{"namespace":"shop"}'
tool get_events "namespace: shop"; call get_events '{"namespace":"shop"}' 3
tool get_pod_logs "pod: $POD, tail: 50"; call get_pod_logs "{\"pod\":\"$POD\",\"namespace\":\"shop\",\"tail\":50}"
echo
say "${B}Root cause:${N} checkout can't reach its database. It dials db:5432, but the only Service in the namespace is orders-db, so DNS for 'db' fails."
say "${B}Evidence:${N} FATAL connection refused: db:5432 · BackOff events · restarts climbing."
say "${B}Proposed fix:${N} expose the DB as Service 'db', then restart checkout. Want me to restart it?"
pause 1.5
shell "./scripts/fix-db.sh"

section "3. Restart, with approval"
ask "Yes - restart checkout"
printf '  %s┃%s %sAllow k8s-assistant to run restart_deployment?%s\n' "$Y" "$N" "$B" "$N"
printf '  %s┃%s name: checkout   namespace: shop   %s(destructive)%s\n' "$Y" "$N" "$R" "$N"
printf '  %s┃%s %s[y] allow   [n] deny%s\n' "$Y" "$N" "$D" "$N"
pause 2; printf '  '; type_out "y"; echo; pause 0.5
tool restart_deployment "name: checkout, namespace: shop"
call restart_deployment '{"name":"checkout","namespace":"shop"}'
[ "$SPEED" = 0 ] || sleep 12
echo; section "4. Recovered"
shell "kubectl get pods -n shop"

section "5. Guardrail"
ask "Restart the checkout deployment in namespace prod"
tool restart_deployment "name: checkout, namespace: prod"
call restart_deployment '{"name":"checkout","namespace":"prod"}'
echo; pause 1

section "6. RBAC is the real boundary"
shell "./scripts/prove-rbac.sh"

section "7. Audit trail"
shell "./scripts/show-audit.sh 4"
