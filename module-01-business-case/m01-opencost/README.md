# Lab 1.10: Seeing GPU cost in your cluster with OpenCost

Production AI on Kubernetes, Module 1. You install OpenCost on a local kind cluster, give it Meridale's GPU price, and see what each team's namespace costs, including the GPU nobody asked for (idle cost).

**Runs only on your machine: no cloud account, no cost.** It creates its own kind cluster, `m01-opencost`; your other clusters are untouched.

**Tested on macOS (Apple silicon MacBook)** with Colima 4 CPUs / 8 GB, kind v0.33.0 (Kubernetes v1.37), kubectl v1.37.1 and Helm v4.3.1, the tools from lab 0.13. OpenCost 1.121.3 (Helm chart 2.5.33) and Prometheus v3.15.1 (chart 29.40.3) were installed on the day. Other systems may work, but we haven't tested them.

## The GPUs are pretend

Your laptop has no NVIDIA GPU, so one worker node advertises two `nvidia.com/gpu` as an extended resource (Kubernetes docs: "Advertise Extended Resources for a Node"). The scheduler hands them out like real GPUs, and OpenCost prices them like real GPUs. What OpenCost can't do here is measure how busy a GPU is: that needs NVIDIA's DCGM exporter on a real GPU, so GPU efficiency shows 0.

## Before you start: the Colima file-watch limit

kind's known-issues page warns that clusters with several nodes can fail with "too many open files". On our Colima VM the limit `fs.inotify.max_user_instances` was 128, and `kube-proxy` crashed on both workers with `fsnotify watcher init: too many open files`. Pods on the workers then couldn't reach any Service, and OpenCost stopped at start-up. `bash opencost-lab.sh check` tests this. To fix it (until Colima restarts):

```bash
colima ssh -- sudo sysctl -w fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=1048576
```

## Files

| File | What it is |
|---|---|
| `opencost-lab.sh` | `check`, `up`, `report`, `ui`, `down` |
| `opencost-values.yaml` | OpenCost custom pricing: GPU $0.8048 per hour (one L4 on demand, AWS us-east-1, 5 Nov 2026, from lab 1.9); CPU, RAM and storage at OpenCost's defaults |
| `meridale-workloads.yaml` | Ask Meridale (`assistant`) requests 1 GPU; Atlas data prep (`atlas`) requests CPU only |
| `kind-config.yaml`, `namespaces.yaml` | The cluster and Meridale's team namespaces, same as lab 0.13 |
| `our-results/` | Our recorded run of 5 Nov 2026: the transcript and OpenCost's answers. The transcript's report ends with a "per hour at this rate" line that was wrong (it divided by the whole window, but the GPU line covers only the minutes the workload ran); that line has since been removed from `opencost-lab.sh`. |

`kind-config.yaml` and `namespaces.yaml` are copies of the ones from lab 0.13 (`m00-lab-setup`), so this folder works on its own.

## Steps

Run these from this folder.

**1. Check, then bring it up** (about 5 minutes):

```bash
bash opencost-lab.sh check
bash opencost-lab.sh up
```

`up` creates the cluster, adds the two pretend GPUs, installs Prometheus and OpenCost with the commands from the OpenCost docs, and starts Meridale's two workloads.

**2. Wait about 15 minutes**, so Prometheus and OpenCost have data. Then:

```bash
bash opencost-lab.sh report
```

You get the GPUs and GPU price OpenCost sees per node, then the cost of each namespace over the last 15 minutes, with `__idle__` for capacity nobody requested. Change the window with `WINDOW=30m bash opencost-lab.sh report`.

**3. Look around the UI** (optional):

```bash
bash opencost-lab.sh ui
```

Open http://localhost:9090. Ctrl+C stops it.

**4. Delete the cluster:**

```bash
bash opencost-lab.sh down
```

## What to look for

- The GPU node shows 2 GPUs at $0.8048 per GPU-hour.
- `assistant` is charged for one GPU; `atlas` for CPU and memory only.
- `__idle__` carries the other GPU: half the GPU bill pays for nothing. That's the utilisation problem from lab 1.9, now visible per team.

## Sources

- OpenCost docs: installing Prometheus; on-prem install and custom pricing with the Helm chart; API (`/allocation`, `includeIdle`); metrics (`node_gpu_count`, `node_gpu_hourly_cost`); specification (idle costs).
- Kubernetes docs: Advertise Extended Resources for a Node.
- kind docs: known issues, Pod errors due to "too many open files".
