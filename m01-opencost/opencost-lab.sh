#!/usr/bin/env bash
# Lab 1.10: seeing GPU cost in your cluster with OpenCost.
#
#   bash opencost-lab.sh check     # tools, and the Colima file-watch limit kind needs
#   bash opencost-lab.sh up        # cluster, 2 pretend GPUs, Prometheus, OpenCost, Meridale's workloads (about 5 minutes)
#   bash opencost-lab.sh report    # ask OpenCost what each namespace costs (wait 15 minutes after `up` first)
#   bash opencost-lab.sh ui        # open the OpenCost UI on http://localhost:9090 (Ctrl+C to stop)
#   bash opencost-lab.sh down      # delete the lab cluster
#
# Runs only on your machine: no cloud account, no cost. Uses its own kind cluster "m01-opencost"; your other clusters are untouched.
# The GPUs are pretend: one worker advertises 2 x nvidia.com/gpu (Kubernetes docs, "Advertise Extended Resources for a Node").
# OpenCost prices and allocates them like real ones, but it can't measure how busy they are (no NVIDIA DCGM exporter).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SETUP="$HERE/../m00-lab-setup"
CLUSTER=m01-opencost
CTX=kind-$CLUSTER
GPU_NODE=$CLUSTER-worker
WINDOW=${WINDOW:-15m}
k(){ printf '$ kubectl %s\n' "$*"; kubectl --context "$CTX" "$@"; }
say(){ printf '\n== %s\n' "$*"; }

cmd_check(){
  say "tools"
  kind version && kubectl version --client | head -1 && helm version --short || return 1
  say "Colima file-watch limit (kind known issue: 'too many open files')"
  local inst
  inst=$(colima ssh -- sysctl -n fs.inotify.max_user_instances 2>/dev/null | tr -d '\r')
  echo "fs.inotify.max_user_instances = ${inst:-unknown} (kind recommends 512)"
  if [ -n "$inst" ] && [ "$inst" -lt 512 ]; then
    echo "Too low: kube-proxy will crash on the worker nodes. Raise it (lasts until Colima restarts):"
    echo "  colima ssh -- sudo sysctl -w fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=1048576"
    return 1
  fi
  echo "ok"
}

cmd_up(){
  cmd_check || exit 1
  say "1 cluster"
  kind create cluster --name "$CLUSTER" --config "$SETUP/kind-config.yaml" || exit 1
  k -n kube-system wait --for=condition=Ready pod -l k8s-app=kube-proxy --timeout=120s || exit 1
  say "2 two pretend GPUs on $GPU_NODE"
  k patch node "$GPU_NODE" --subresource=status --type=json -p '[{"op":"add","path":"/status/capacity/nvidia.com~1gpu","value":"2"}]'
  say "3 Prometheus (OpenCost docs command)"
  helm install prometheus --repo https://prometheus-community.github.io/helm-charts prometheus \
    --kube-context "$CTX" --namespace prometheus-system --create-namespace \
    --set prometheus-pushgateway.enabled=false --set alertmanager.enabled=false \
    -f https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/prometheus/extraScrapeConfigs.yaml || exit 1
  say "4 OpenCost, with our prices"
  cat "$HERE/opencost-values.yaml"
  k create namespace opencost
  helm install opencost --repo https://opencost.github.io/opencost-helm-chart opencost \
    --kube-context "$CTX" --namespace opencost -f "$HERE/opencost-values.yaml" || exit 1
  k -n prometheus-system rollout status deploy/prometheus-server --timeout=300s
  k -n opencost rollout status deploy/opencost --timeout=600s || { k -n opencost logs deploy/opencost --all-containers --tail=20; exit 1; }
  say "5 Meridale's workloads"
  k apply -f "$SETUP/namespaces.yaml"
  k apply -f "$HERE/meridale-workloads.yaml"
  k -n assistant rollout status deploy/ask-meridale --timeout=180s
  k -n atlas rollout status deploy/atlas-prep --timeout=180s
  k get node "$GPU_NODE" -o jsonpath='{"nvidia.com/gpu allocatable: "}{.status.allocatable.nvidia\.com/gpu}{"\n"}'
  k describe node "$GPU_NODE" | grep -E "^\s+nvidia.com/gpu" | tail -1
  echo
  echo "Up. Give Prometheus and OpenCost about 15 minutes to collect, then: bash opencost-lab.sh report"
}

cmd_report(){
  mkdir -p "$HERE/runs"
  local out="$HERE/runs/opencost-$(date +%Y%m%d-%H%M%S)"
  kubectl --context "$CTX" -n opencost port-forward service/opencost 9003 >/dev/null 2>&1 &
  local pf=$!; sleep 4
  say "OpenCost: GPUs and GPU price per node"
  curl -s localhost:9003/metrics | grep -E "^node_gpu_(count|hourly_cost)" | sed -E 's/\{.*node="([^"]+)".*\} / \1 /'
  say "OpenCost: cost by namespace, last $WINDOW, with idle"
  echo "\$ curl 'localhost:9003/allocation/compute?window=$WINDOW&aggregate=namespace&includeIdle=true'"
  curl -s "localhost:9003/allocation/compute?window=$WINDOW&aggregate=namespace&includeIdle=true" > "$out-allocation.json"
  curl -s "localhost:9003/assets?window=$WINDOW" > "$out-assets.json"
  kill $pf 2>/dev/null; wait $pf 2>/dev/null
  python3 - "$out-allocation.json" <<'PY'
import json, sys
sets = json.load(open(sys.argv[1]))["data"]
rows = {}
for s in sets:
    for name, a in (s or {}).items():
        r = rows.setdefault(name, dict(minutes=0, gpuHours=0, gpuCost=0, cpuCost=0, ramCost=0, totalCost=0))
        for key in r:
            r[key] += a.get(key, 0) or 0
gpu_total = sum(r["gpuCost"] for r in rows.values())
mins = max((r["minutes"] for r in rows.values()), default=0)
print(f"window measured: {mins:.0f} minutes")
print(f"{'namespace':18s}{'GPU-hours':>10s}{'GPU $':>9s}{'CPU $':>9s}{'RAM $':>9s}{'total $':>9s}{'share of GPU $':>16s}")
for name, r in sorted(rows.items(), key=lambda kv: -kv[1]["totalCost"]):
    share = r["gpuCost"] / gpu_total if gpu_total else 0
    print(f"{name:18s}{r['gpuHours']:10.4f}{r['gpuCost']:9.4f}{r['cpuCost']:9.4f}{r['ramCost']:9.4f}{r['totalCost']:9.4f}{share:15.0%}")
print(f"GPU cost in the window: ${gpu_total:.4f}" if gpu_total else "no GPU cost yet: wait a few minutes and run report again")
PY
  echo "Saved: $out-allocation.json and $out-assets.json"
}

cmd_ui(){
  echo "OpenCost UI on http://localhost:9090 (Ctrl+C to stop)"
  kubectl --context "$CTX" -n opencost port-forward service/opencost 9003 9090
}

cmd_down(){
  kind delete cluster --name "$CLUSTER"
}

case "${1:-}" in
  check) cmd_check ;; up) cmd_up ;; report) cmd_report ;; ui) cmd_ui ;; down) cmd_down ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
