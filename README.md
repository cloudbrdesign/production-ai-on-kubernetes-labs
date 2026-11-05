# Production AI on Kubernetes: course labs

Lab files for the Cloud Brewery Academy course **Production AI on Kubernetes: Building Compliant Infrastructure for the Enterprise**. The course follows the platform team of Meridale Finance, a fictional consumer lender, as it builds a compliant platform for its AI systems. Labs are grouped in one folder per module; each lab folder has its own README and every file the lab uses.

**Tested on macOS (Apple silicon MacBook).** Every lab was run on a MacBook with Apple silicon, and its README lists the exact versions we used. Other systems may work, but we haven't tested them.

## Labs

Each module folder has a README listing its labs. Each lab folder works on its own.

| Module | Labs |
|---|---|
| [Module 0: Welcome to Meridale's platform team](module-00-welcome/) | [0.13 Setting up your lab environment](module-00-welcome/m00-lab-setup/) |
| [Module 1: The business case](module-01-business-case/) | [1.8 Measuring one L4 GPU](module-01-business-case/m01-l4-throughput/) (AWS, under $1) · [1.9 Meridale's GPU cost model](module-01-business-case/m01-cost-model/) · [1.10 Seeing cost in your cluster with OpenCost](module-01-business-case/m01-opencost/) |

## What you need

A Docker engine with about 8 GB of memory (we use Colima), kind, kubectl and Helm. `module-00-welcome/m00-lab-setup/check-tools.sh` checks them for you; the versions we tested are in each lab's README.

The two AWS labs (`m01-l4-throughput`, and `get_prices.py` in `m01-cost-model`) also need Python 3, boto3 and an AWS account; each README says what it costs (the price pull is free) and what permissions it needs.

## Licence

Code and configuration: Apache-2.0. Guides and other educational content: CC-BY-4.0. See [LICENSING.md](LICENSING.md).
