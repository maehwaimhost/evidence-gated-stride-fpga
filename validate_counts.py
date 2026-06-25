#!/usr/bin/env python3
"""Validate the frozen evaluation counts of the
Evidence-Gated STRIDE for FPGA Development Toolchains evidence package.

Standard library only. Run from anywhere:

    python validate_counts.py

Exits 0 if every check passes, 1 otherwise.
"""
import csv
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))

# The 24 core record identifiers, in catalog order.
EXPECTED_24_IDS = [
    "SIP-1", "SIP-2", "SIP-3", "SIM-1", "SIM-2",
    "CFG-1", "CFG-2", "CFG-3", "TENV-1", "TENV-2", "TENV-3",
    "TRN-1", "TRN-2", "TRN-3", "RPT-1", "RPT-2", "RPT-3",
    "BSD-1", "BSD-2", "BSD-3", "BSD-4", "DEP-1", "REL-1", "REL-2",
]

# (relative path, expected number of data rows)
ROW_COUNT_CHECKS = [
    ("00_stride_fpga_catalog/full_threat_taxonomy_supplement.csv", 24),
    ("00_stride_fpga_catalog/threat_record_schema_full.csv", 24),
    ("block1_construction_audit/candidate_filtering_study.csv", 62),
    ("block1_construction_audit/generic_stride_baseline.csv", 54),
    ("block2_artifact_grounding/cross_vendor_artifact_inventory.csv", 1114),
]


def data_rows(rel_path):
    """Return the data rows of a CSV as a list of dicts (BOM-tolerant)."""
    with open(os.path.join(ROOT, rel_path), newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def main():
    failures = 0

    for rel, expected in ROW_COUNT_CHECKS:
        try:
            n = len(data_rows(rel))
        except FileNotFoundError:
            print("FAIL  %s: file not found" % rel)
            failures += 1
            continue
        ok = (n == expected)
        failures += 0 if ok else 1
        print("%s  %s: %d rows (expected %d)" % ("PASS" if ok else "FAIL", rel, n, expected))

    # Record-identifier set check on the schema master table.
    try:
        rows = data_rows("00_stride_fpga_catalog/threat_record_schema_full.csv")
        first_col = next(iter(rows[0])) if rows else None
        ids = [r[first_col].strip() for r in rows] if first_col else []
        missing = [i for i in EXPECTED_24_IDS if i not in ids]
        extra = [i for i in ids if i not in EXPECTED_24_IDS]
        if missing or extra:
            failures += 1
            print("FAIL  record IDs: missing=%s extra=%s" % (missing, extra))
        else:
            print("PASS  record IDs: all 24 expected identifiers present")
    except FileNotFoundError:
        failures += 1
        print("FAIL  record IDs: schema file not found")

    print()
    if failures:
        print("%d check(s) FAILED" % failures)
        return 1
    print("All checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
