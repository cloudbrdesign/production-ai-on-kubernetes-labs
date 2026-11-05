# Production AI on Kubernetes: course labs

Lab files for the Cloud Brewery Academy course **Production AI on Kubernetes: Building Compliant Infrastructure for the Enterprise**. The course follows the platform team of Meridale Finance, a fictional consumer lender, as it builds a compliant platform for its AI systems. Each folder is one lab, with its own README and every file the lab uses.

**Tested on macOS (Apple silicon MacBook).** Every lab was run on a MacBook with Apple silicon, and its README lists the exact versions we used. Other systems may work, but we haven't tested them.

## Labs

| Lab | Lesson | What you do |
|---|---|---|
| [m00-lab-setup](m00-lab-setup/) | 0.13 Lab: setting up your lab environment | Create the kind cluster every later lab starts from (Kubernetes v1.37), a namespace per team, a Job and a Deployment + Service, delete a Pod and watch it come back, install Kueue with Helm |
| [m01-l4-throughput](m01-l4-throughput/) | 1.8 Lab: measuring one L4 GPU | Optional, on AWS, under $1: launch one g6.xlarge (NVIDIA L4), serve a 7B model with vLLM, measure tokens per second at 1 to 64 requests at a time, delete everything. Our results are included |
| [m01-cost-model](m01-cost-model/) | 1.9 Lab: Meridale's GPU cost model | Pull today's GPU prices from AWS (read-only), then a spreadsheet: cost per million tokens, GPUs needed, monthly bill, Spot vs on-demand, own hardware. Meridale's filled model and a blank template |
| [m01-opencost](m01-opencost/) | 1.10 Lab: seeing cost in your cluster with OpenCost | Local, no cost: OpenCost on a kind cluster with two pretend GPUs; GPU cost per namespace and the idle GPU nobody asked for |

More labs are added as each module is released.

## What you need

A Docker engine with about 8 GB of memory (we use Colima), kind, kubectl and Helm. `m00-lab-setup/check-tools.sh` checks them for you; the versions we tested are in `m00-lab-setup/README.md`.

The two AWS labs (`m01-l4-throughput`, and `get_prices.py` in `m01-cost-model`) also need Python 3, boto3 and an AWS account; each README says what it costs (the price pull is free) and what permissions it needs.

## Licence

Code and configuration: Apache-2.0. Guides and other educational content: CC-BY-4.0. See [LICENSING.md](LICENSING.md).
