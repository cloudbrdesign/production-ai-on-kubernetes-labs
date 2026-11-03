# Lab 0.13: Setting up your lab environment

Production AI on Kubernetes, Module 0. You build the local cluster every later lab starts from, run a stand-in for two of Meridale's systems on it, break one on purpose, and install the first platform tool with Helm.

**Tested on macOS (Apple silicon MacBook, macOS 27.2).** The versions we tested are below. Other systems may work, but we haven't tested them. Our full run took under two minutes once the images were downloaded.

## What you need

| Tool | Tested version | Install (macOS) |
|---|---|---|
| A Docker engine with about 8 GB of memory | Colima 0.10.3, Docker 29.5.2 (4 CPUs, 7.7 GiB) | `brew install colima docker`, then `colima start --cpu 4 --memory 8` |
| kind | v0.33.0 | `brew install kind` |
| kubectl | v1.37.1 | `brew install kubectl`, or the curl install in the Kubernetes docs |
| Helm | v4.3.1 | `brew install helm` |

kind runs each Kubernetes node as a container in Docker. Its docs ask for at least 6 GB of memory for the Docker VM on macOS, and 8 GB is recommended.

## Files

| File | What it is |
|---|---|
| `check-tools.sh` | Checks the tools and Docker's memory, prints versions |
| `kind-config.yaml` | The cluster: one control plane and two workers, Kubernetes v1.37 |
| `namespaces.yaml` | One namespace per Meridale team: `atlas`, `sentinel`, `assistant`, `nudge` |
| `atlas-train.yaml` | Stand-in for Atlas training: a Job that runs five "epochs" and stops |
| `sentinel-scoring.yaml` | Stand-in for Sentinel scoring: a Deployment of three Pods behind a Service |

## Steps

Run these from this folder.

**1. Check your tools.**

```bash
bash check-tools.sh
```

Every line should say `ok`, and Docker should report about 8 GB. If Docker isn't running, start it (`colima start`).

**2. Create the cluster.**

```bash
kind create cluster --name meridale --config kind-config.yaml
kubectl get nodes -o wide
```

Expect three nodes, all `Ready`, all on `v1.37.0`. The first time, kind downloads the node image, which takes a few minutes. The image we tested is `kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5`; kind's docs recommend pinning the digest, so you can add it after the tag in `kind-config.yaml`.

**3. Create a namespace per team.**

```bash
kubectl apply -f namespaces.yaml
kubectl get namespaces
```

**4. Run Atlas training as a Job.**

```bash
kubectl apply -f atlas-train.yaml
kubectl wait --for=condition=complete job/atlas-train -n atlas --timeout=180s
kubectl get job,pods -n atlas
kubectl logs job/atlas-train -n atlas
```

The Pod ends as `Completed` and the log ends with `model saved`.

**5. Run Sentinel scoring as a Deployment and a Service.**

```bash
kubectl apply -f sentinel-scoring.yaml
kubectl rollout status deployment/sentinel-scoring -n sentinel
kubectl get deployment,pods,service -n sentinel -o wide
kubectl run probe -n sentinel --rm -i --restart=Never --image=busybox:1.37 -- wget -qO- http://sentinel-scoring | grep title
```

Three Pods, spread across the two workers. The probe reaches them through the Service's name and prints `<title>Welcome to nginx!</title>`. If you only see `pod "probe" deleted`, the probe finished before kubectl attached to it (this happened in one of our runs): run the same command again.

**6. Break it: delete a Pod.**

```bash
kubectl get pods -n sentinel
kubectl delete pod <one of the sentinel-scoring Pod names> -n sentinel
kubectl get pods -n sentinel
```

The Deployment notices it has two Pods instead of three and creates a new one, with a new name.

**7. Install Kueue with Helm.**

```bash
helm install kueue oci://registry.k8s.io/kueue/charts/kueue \
  --version=0.20.4 \
  --namespace kueue-system \
  --create-namespace \
  --wait --timeout 300s
kubectl get pods -n kueue-system
helm list -A
kubectl api-resources --api-group=kueue.x-k8s.io
```

Kueue is the job queueing system we use in Module 3. Its docs recommend Kubernetes 1.35 or newer. For now, check that its controller Pod is `1/1 Running` and the release is `deployed`.

**8. Clean up.**

```bash
kind delete cluster --name meridale
```

## If something goes wrong

- **`Cannot connect to the Docker daemon`**: your Docker engine isn't running. `colima start`, then run the step again.
- **A cluster named `meridale` already exists**: delete it (`kind delete cluster --name meridale`) and create it again.
- **`helm install` for Kueue fails with `context deadline exceeded`**: Helm waited 5 minutes and the controller wasn't ready. In one of our runs the controller showed `0/1 Running` with 2 restarts and the release was `failed`; on a fresh cluster the same command finished in under 30 seconds. Look at `kubectl describe pods -n kueue-system` and `kubectl get events -n kueue-system`, then either wait and check again, or delete the cluster, create it again and repeat steps 2 and 7.
- **Pods stuck in `ErrImagePull` or `ImagePullBackOff`**: the node couldn't download an image. Check your internet connection, then `kubectl describe pod <name> -n <namespace>`.

## Sources

- kind quick start (installation, creating and deleting clusters, Docker memory on macOS): kubernetes-sigs/kind docs.
- Installing kubectl on macOS: kubernetes.io docs.
- Kueue installation by Helm (v0.20.4): kubernetes-sigs/kueue docs, `site/content/en/docs/getting-started/installation.md`.
- Helm 4 quick start: helm.sh docs.
