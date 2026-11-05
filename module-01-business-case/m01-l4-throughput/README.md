# Lab 1.8: Measuring one L4 GPU

Production AI on Kubernetes, Module 1. You measure how many tokens per second one NVIDIA L4 serves, and at what latency, so the Module 1 cost model runs on a measured number instead of a guess. The same measurement is reused in Module 6.

**Optional, and under $1.** This lab runs on AWS and you pay AWS for it. If you'd rather not, use our results: `our-results/aws-20261105-073451.txt` (5 Nov 2026) and `our-results/aws-20261030-100802.txt` (30 Oct 2026) are in this folder, and lab 1.9's cost model already uses them.

**Tested from macOS (Apple silicon MacBook)** with Python 3 and boto3 1.43.103. The script runs on your machine and only talks to AWS's APIs; the GPU work happens on the AWS instance. Other systems may work, but we haven't tested them.

## What runs

| | |
|---|---|
| Instance | one `g6.xlarge` (1× NVIDIA L4, 4 vCPUs), us-east-1 first, then us-east-2 and us-west-2 |
| Server | vLLM `v0.32.0` in Docker |
| Model | `Qwen/Qwen2.5-7B-Instruct`, max context 4,096 tokens |
| Benchmark | `vllm bench serve`, 512 input and 256 output tokens per request, at 1, 4, 8, 16, 32 and 64 requests at a time |
| Recorded | output and total tokens/s, requests/s, TTFT, TPOT and ITL (mean and P99), GPU power and utilisation |

Source for the benchmark commands and metric definitions: vLLM v0.32.0 docs, `docs/benchmarking/cli.md`.

## Cost rules built in

- The instance **terminates itself 55 minutes after boot**, even if you forget `down`.
- No inbound ports and no SSH key: results come back through the instance console.
- `down` deletes everything `up` created (the instance, its disk, the launch template and the security group) and waits until AWS confirms it.
- Our run: about 45 minutes of instance time at $0.8048 an hour on demand (AWS Price List API, us-east-1, 5 Nov 2026) ≈ $0.60, plus a few cents of disk. **Check today's price before `up`** (lab 1.9's `get_prices.py` prints it).

## What you need

- An AWS account with credentials that boto3 can find (for example `aws configure`, or `AWS_PROFILE`). The account needs permission for EC2, CloudFormation, Service Quotas and SSM Parameter Store (read, to find the GPU image).
- **4 vCPUs of "Running On-Demand G and VT instances" quota** in at least one of the three regions. If `quota` shows 0 everywhere, request an increase in the Service Quotas console (it can take a while), or use our results.
- Python 3 and boto3: `pip install -r aws/requirements.txt`

## Steps

Run these from this folder.

**1. Check your quota.** Nothing is created.

```bash
python3 aws/l4_throughput.py quota
```

You need one region with at least 4 vCPUs.

**2. Launch.** The instance pulls vLLM, downloads the model and runs the whole benchmark by itself. The script prints progress; the full run takes about 30 to 40 minutes.

```bash
python3 aws/l4_throughput.py up
```

If a zone has no `g6.xlarge` capacity, the script tries the next zone and region. (Ours did: us-east-1a had none, us-east-1b worked.)

**3. Get the results** (if `up` was interrupted before it saved them).

```bash
python3 aws/l4_throughput.py results
```

Your results land in `runs/aws-<date-time>.log`.

**4. Delete everything, then check.**

```bash
python3 aws/l4_throughput.py down
python3 aws/l4_throughput.py status
```

`status` should say nothing from this measurement is running. Ours took just under 7 minutes to delete.

## Our results (5 Nov 2026)

| Requests at a time | Output tokens/s | P99 time to first token (ms) |
|---|---|---|
| 1 | 17.51 | 171.34 |
| 4 | 65.63 | 691.28 |
| 8 | 125.37 | 1,229.66 |
| 16 | 229.54 | 2,215.14 |
| 32 | 375.87 | 4,575.33 |
| 64 | 582.18 | 9,074.51 |

Every throughput figure is within about 1% of our 30 Oct run (the largest gap is at 32: −1.1%).

## Files

| File | What it is |
|---|---|
| `aws/l4_throughput.py` | The five commands: `quota`, `up`, `results`, `status`, `down` |
| `aws/throughput.yaml` | The CloudFormation stack `up` creates |
| `aws/requirements.txt` | boto3 version we tested |
| `our-results/` | Our two recorded runs, exactly as the script saved them |
| `runs/` | Created on your first run; your own results go here |
