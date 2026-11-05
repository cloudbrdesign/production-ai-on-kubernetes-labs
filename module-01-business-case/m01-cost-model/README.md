# Lab 1.9: Meridale's GPU cost model

Production AI on Kubernetes, Module 1. One spreadsheet that turns GPU prices and a measured throughput into cost per million tokens, GPUs needed and a monthly bill for an always-on AI assistant, cost per training run, and NVIDIA's method for pricing owned hardware.

**Tested on macOS (Apple silicon MacBook)** with Python 3 and boto3 1.43.103; the workbooks were recalculated in LibreOffice. Other systems may work, but we haven't tested them.

## Files

| File | What it is |
|---|---|
| `Meridale_GPU_Cost_Model.xlsx` | Meridale's model, filled: AWS prices pulled 5 Nov 2026, our L4 run of 5 Nov 2026, illustrative demand |
| `GPU_Cost_Model_Template.xlsx` | The same formulas, blank, for your own organisation |
| `get_prices.py` | Pulls today's prices from AWS's own APIs (read-only; nothing is created) |
| `our-results/prices-20261105-074204.txt` | The prices we used, exactly as the script printed them |

## Get today's prices (optional)

Needs AWS credentials boto3 can find, with read access to the Price List API, EC2 (`DescribeSpotPriceHistory`) and Savings Plans (`DescribeSavingsPlansOfferingRates`). Nothing is created and nothing is charged.

```bash
pip install boto3
python3 get_prices.py
```

It prints on-demand, Spot by Availability Zone and no-upfront Savings Plan rates for `g6.xlarge`, `p4d.24xlarge` and `p5.48xlarge` in us-east-1, and saves them to `runs/prices-<date-time>.log`. Copy them into the Prices sheet (blue cells).

## Use the model

1. **Prices:** today's prices, or ours.
2. **L4 benchmark:** our run (lab 1.8) or yours.
3. **Ask Meridale serving:** latency target and demand (yellow cells) → GPUs needed, monthly bill, effective cost per million tokens; then the Savings Plan + on-demand plan.
4. **Atlas training:** GPU-hours per run → on-demand vs Spot.
5. **Own hardware:** NVIDIA's example, or your own server's numbers.

Yellow cells are assumptions to replace. Black cells are formulas; green cells come from another sheet. List prices only: no taxes, storage, networking, support or staff.
