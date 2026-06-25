#!/usr/bin/env python3
"""Verify Block 2 (artifact grounding) frozen data for the
Evidence-Gated STRIDE for FPGA Development Toolchains evidence package.

Standard library only. Run from anywhere:

    python block2_artifact_grounding/verify_block2.py

Checks the 1114-file cross-vendor inventory and its 207/396/504/7 vendor split,
the 72-row per-record recoverability table, the 12 perturbation traces, and the
6 variant runs. This verifies the shipped Block-2 data; it does NOT rebuild the
inventory (that needs AMD Vivado / Intel Quartus / Microchip Libero via
reproduce/run_all.ps1). Exits 0 if every check passes, 1 otherwise.
"""
import collections
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VENDOR_SPLIT = {
    "AMD Vivado": 207,
    "Intel Quartus Prime Pro": 396,
    "Microchip Libero SoC": 504,
    "Common Design Input": 7,
}
ROW_COUNTS = [
    ("block2_artifact_grounding/cross_vendor_artifact_inventory.csv", 1114, "inventory files"),
    ("block2_artifact_grounding/cross_vendor_threat_evidence_recoverability.csv", 72, "recoverability rows (24x3)"),
    ("block2_artifact_grounding/artifact_perturbation_evidence_trace.csv", 12, "perturbation traces"),
    ("block2_artifact_grounding/variant_run_status.csv", 6, "variant runs"),
]


def data_rows(rel_path):
    with open(os.path.join(ROOT, rel_path), newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def main():
    failures = 0
    try:
        for rel, expected, name in ROW_COUNTS:
            n = len(data_rows(rel))
            ok = (n == expected)
            failures += 0 if ok else 1
            print("%s  %s: %d (expected %d)" % ("PASS" if ok else "FAIL", name, n, expected))

        inv = data_rows("block2_artifact_grounding/cross_vendor_artifact_inventory.csv")
        split = dict(collections.Counter(r["vendor"].strip() for r in inv))
        if split == VENDOR_SPLIT:
            print("PASS  vendor split: %s" % split)
        else:
            failures += 1
            print("FAIL  vendor split: got %s expected %s" % (split, VENDOR_SPLIT))
    except FileNotFoundError as exc:
        failures += 1
        print("FAIL  file not found: %s" % exc)

    print()
    if failures:
        print("%d check(s) FAILED" % failures)
        return 1
    print("All Block 2 checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
