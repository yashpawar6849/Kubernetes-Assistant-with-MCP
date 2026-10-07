#!/usr/bin/env bash
# Pretty one-line-per-call view of the audit log: time  tool  args  ->  result
cd "$(dirname "$0")/.."
python3 - "${1:-4}" <<'PY'
import json, sys
DIM, YEL, RED, GRN, OFF = "\033[2m", "\033[33m", "\033[31m", "\033[32m", "\033[0m"
for line in open("audit.log").read().splitlines()[-int(sys.argv[1]):]:
    e = json.loads(line)
    args = ", ".join(f"{k}={str(v)[:22]}" for k, v in e["args"].items())
    res = e["result"].replace("\n", " ")
    colour = RED if res.startswith(("ValueError", "Kubernetes API error")) else GRN
    print(f"{DIM}{e['time'][11:19]}{OFF} {YEL}{e['tool']:<19}{OFF} {args}")
    print(f"         {colour}-> {res[:78]}{OFF}")
PY
