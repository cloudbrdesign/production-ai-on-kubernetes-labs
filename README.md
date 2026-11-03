# Production AI on Kubernetes: course labs

Lab files for the Cloud Brewery Academy course **Production AI on Kubernetes: Building Compliant Infrastructure for the Enterprise**. The course follows the platform team of Meridale Finance, a fictional consumer lender, as it builds a compliant platform for its AI systems. Each folder is one lab, with its own README and every file the lab uses.

**Tested on macOS (Apple silicon MacBook).** Every lab was run on a MacBook with Apple silicon, and its README lists the exact versions we used. Other systems may work, but we haven't tested them.

## Labs

| Lab | Lesson | What you do |
|---|---|---|
| [m00-lab-setup](m00-lab-setup/) | 0.13 Lab: setting up your lab environment | Create the kind cluster every later lab starts from (Kubernetes v1.37), a namespace per team, a Job and a Deployment + Service, delete a Pod and watch it come back, install Kueue with Helm |

More labs are added as each module is released.

## What you need

A Docker engine with about 8 GB of memory (we use Colima), kind, kubectl and Helm. `m00-lab-setup/check-tools.sh` checks them for you; the versions we tested are in `m00-lab-setup/README.md`.

## Licence

Code and configuration: Apache-2.0. Guides and other educational content: CC-BY-4.0. See [LICENSING.md](LICENSING.md).
