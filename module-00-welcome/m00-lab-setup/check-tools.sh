#!/usr/bin/env bash
# Checks the tools the course labs need and prints their versions.
# Tested on macOS (Apple silicon MacBook). Run:  bash check-tools.sh
ok=0
need(){ if command -v "$1" >/dev/null 2>&1; then printf '  ok       %-8s %s\n' "$1" "$2"; else printf '  MISSING  %s\n' "$1"; ok=1; fi; }
echo "Tools"
need docker  "$(docker version --format 'client {{.Client.Version}}, server {{.Server.Version}} ({{.Server.Os}}/{{.Server.Arch}})' 2>/dev/null)"
need kind    "$(kind version 2>/dev/null)"
need kubectl "$(kubectl version --client 2>/dev/null | head -1)"
need helm    "$(helm version --short 2>/dev/null)"
echo "Docker engine"
if docker info >/dev/null 2>&1; then
  cpus=$(docker info --format '{{.NCPU}}'); mem=$(docker info --format '{{.MemTotal}}')
  gib=$(awk -v m="$mem" 'BEGIN{printf "%.1f", m/1073741824}')
  printf '  running  %s CPUs, %s GiB memory\n' "$cpus" "$gib"
  awk -v g="$gib" 'BEGIN{exit !(g<7.5)}' && { echo "  WARNING  less than 8 GB for Docker; the labs are tested with about 8 GB"; ok=1; }
else
  echo "  NOT RUNNING  start your Docker engine first (we use Colima:  colima start)"; ok=1
fi
[ $ok -eq 0 ] && echo "All set." || echo "Fix the lines above, then run this again."
exit $ok
