"""Lab 1.9: pull today's AWS GPU prices from AWS's own APIs (no third-party sites), for the cost model.

    python get_prices.py                 # us-east-1; writes runs/prices-<time>.log next to this file

Needs AWS credentials (the same ones as the L4 lab) and boto3. Read-only: it creates nothing and costs nothing.
Prices: On-Demand (AWS Price List API), Spot (latest price per Availability Zone, EC2 Spot price history),
EC2 Instance and Compute Savings Plans (Savings Plans offering rates, No Upfront, 1 and 3 years).
"""
import datetime as dt
import json
import pathlib
import sys

import boto3

REGION = "us-east-1"
LOCATION = "US East (N. Virginia)"
TYPES = ["g6.xlarge", "p4d.24xlarge", "p5.48xlarge"]
HERE = pathlib.Path(__file__).parent
out = []


def say(s=""):
    print(s)
    out.append(s)


def on_demand(itype):
    pr = boto3.client("pricing", region_name="us-east-1")
    f = [("instanceType", itype), ("location", LOCATION), ("operatingSystem", "Linux"), ("tenancy", "Shared"),
         ("preInstalledSw", "NA"), ("capacitystatus", "Used"), ("licenseModel", "No License required")]
    r = pr.get_products(ServiceCode="AmazonEC2", Filters=[{"Type": "TERM_MATCH", "Field": k, "Value": v} for k, v in f], MaxResults=10)
    prices = []
    for item in r["PriceList"]:
        p = json.loads(item)
        for term in p["terms"].get("OnDemand", {}).values():
            for dim in term["priceDimensions"].values():
                usd = float(dim["pricePerUnit"]["USD"])
                if usd > 0:  # skip $0 entries (e.g. reservation placeholders)
                    prices.append(usd)
    return prices


def spot(itype):
    ec2 = boto3.client("ec2", region_name=REGION)
    r = ec2.describe_spot_price_history(InstanceTypes=[itype], ProductDescriptions=["Linux/UNIX"],
                                        StartTime=dt.datetime.now(dt.timezone.utc), MaxResults=50)
    latest = {}
    for h in r["SpotPriceHistory"]:
        az = h["AvailabilityZone"]
        if az not in latest or h["Timestamp"] > latest[az][1]:
            latest[az] = (float(h["SpotPrice"]), h["Timestamp"])
    return {az: p for az, (p, _) in sorted(latest.items())}


def savings_plans(itype):
    sp = boto3.client("savingsplans", region_name="us-east-1")
    rows = []
    for kind in ("EC2Instance", "Compute"):
        try:
            r = sp.describe_savings_plans_offering_rates(
                savingsPlanTypes=[kind], savingsPlanPaymentOptions=["No Upfront"], products=["EC2"], serviceCodes=["AmazonEC2"],
                filters=[{"name": "instanceType", "values": [itype]}, {"name": "region", "values": [REGION]},
                         {"name": "tenancy", "values": ["shared"]}, {"name": "productDescription", "values": ["Linux/UNIX"]}],
                maxResults=100)
            for x in r.get("searchResults", []):
                if x.get("usageType", "").endswith(f"BoxUsage:{itype}"):
                    rows.append((kind, x["savingsPlanOffering"]["durationSeconds"] // 31536000, float(x["rate"])))
        except Exception as e:  # report, don't stop
            rows.append((kind, 0, f"error: {e.__class__.__name__}"))
    return sorted(set(rows), key=str)


def main():
    say(f"prices pulled {dt.datetime.now(dt.timezone.utc):%Y-%m-%d %H:%M} UTC · region {REGION} · Linux, shared tenancy · USD per instance-hour")
    for t in TYPES:
        say(f"\n== {t}")
        od = on_demand(t)
        say(f"on-demand: {', '.join(f'{p:.4f}' for p in od) or 'not found'}")
        for az, p in spot(t).items():
            say(f"spot {az}: {p:.4f}")
        for kind, years, rate in savings_plans(t):
            say(f"savings plan {kind} {years}yr no-upfront: {rate if isinstance(rate, str) else f'{rate:.4f}'}")
    (HERE / "runs").mkdir(exist_ok=True)
    p = HERE / "runs" / f"prices-{dt.datetime.now():%Y%m%d-%H%M%S}.log"
    p.write_text("\n".join(out) + "\n")
    print(f"\nSaved to {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
