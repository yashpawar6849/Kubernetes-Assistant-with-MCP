#!/usr/bin/env bash
# Checks tools; offers Homebrew installs for anything missing (macOS).
set -uo pipefail
declare -A BREW=([docker]="--cask docker" [kind]=kind [kubectl]=kubectl [uv]=uv [python3]=python@3.12)
missing=0
for t in docker kind kubectl python3 uv; do
  if command -v "$t" >/dev/null; then printf '  ok       %s\n' "$t"; continue; fi
  printf '  MISSING  %s\n' "$t"; missing=1
  if command -v brew >/dev/null; then brew install ${BREW[$t]}; else echo "    install Homebrew first: https://brew.sh"; fi
done
python3 -c 'import sys; sys.exit(sys.version_info < (3,10))' && echo "  ok       python $(python3 -V | cut -d" " -f2) (>=3.10)" || echo "  TOO OLD  python3 (need 3.10+)"
docker info >/dev/null 2>&1 && echo "  ok       docker daemon running" || { echo "  ACTION   start Docker Desktop, then re-run"; missing=1; }
exit $missing
