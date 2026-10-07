#!/usr/bin/env bash
# Demo moment: ask the API server what the assistant's identity may do.
source "$(dirname "$0")/_common.sh"
SA=system:serviceaccount:shop:mcp-assistant
G=$'\e[32m'; R=$'\e[31m'; N=$'\e[0m'
check() {  # expected, description, can-i args...
  local want=$1 desc=$2; shift 2
  local got; got=$(k auth can-i "$@" --as "$SA" 2>/dev/null)
  if [ "$got" = "$want" ]; then c=$G; else c=$R; fi
  printf "  %-34s %s%s%s\n" "$desc" "$c" "$got" "$N"
}
echo "Identity: $SA"
echo "Allowed:"
check yes "get pods in shop"            get pods -n shop
check yes "read pod logs in shop"       get pods --subresource=log -n shop
check yes "list events in shop"         list events -n shop
check yes "patch deployments in shop"   patch deployments -n shop
echo "Denied:"
check no  "read secrets in shop"        get secrets -n shop
check no  "exec into pods in shop"      create pods --subresource=exec -n shop
check no  "delete pods in shop"         delete pods -n shop
check no  "delete deployments in shop"  delete deployments -n shop
check no  "restart anything in prod"    patch deployments -n prod
check no  "read pods in kube-system"    get pods -n kube-system
