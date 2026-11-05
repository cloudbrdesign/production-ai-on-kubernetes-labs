# Module 1: The business case

| Lab | Lesson | What you do | Runs on | Cost |
|---|---|---|---|---|
| [m01-l4-throughput](m01-l4-throughput/) | 1.8 Lab: measuring one L4 GPU | Launch one g6.xlarge (NVIDIA L4), serve a 7B model with vLLM, measure tokens per second at 1 to 64 requests at a time, delete everything. Optional: our results are included | AWS | Under $1 |
| [m01-cost-model](m01-cost-model/) | 1.9 Lab: Meridale's GPU cost model | Pull today's GPU prices from AWS (read-only), then a spreadsheet: cost per million tokens, GPUs needed, monthly bill, Spot vs on-demand, own hardware. Meridale's filled model and a blank template | Spreadsheet; AWS for the price pull | None |
| [m01-opencost](m01-opencost/) | 1.10 Lab: seeing cost in your cluster with OpenCost | OpenCost on a kind cluster with two pretend GPUs: GPU cost per namespace, and the idle GPU nobody asked for | Your machine (kind) | None |

Each folder works on its own and has its own README with the exact versions we tested. The AWS labs need Python 3, boto3 and an AWS account; their READMEs say what permissions they use.
