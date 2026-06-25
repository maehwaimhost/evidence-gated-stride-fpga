#!/usr/bin/env python3
"""Verify Block 1 (construction audit) frozen splits for the
Evidence-Gated STRIDE for FPGA Development Toolchains evidence package.

Standard library only. Run from anywhere:

    python block1_construction_audit/verify_block1.py

Checks the 62-candidate disposition split, the 54-question baseline split, and
that the 24 audit-snapshot record IDs match the core catalog. Exits 0 if every
check passes, 1 otherwise.
"""
import collections
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CANDIDATE_DISPOSITIONS = {
    "retained_distinct": 18,
    "rewritten_to_retained": 16,
    "merged_duplicate": 11,
    "excluded_generic_IT": 8,
    "excluded_physical_runtime": 7,
    "excluded_no_evidence_requirement": 2,
}
BASELINE_STATUSES = {
    "direct_retained": 28,
    "requires_artifact_rewrite": 11,
    "generic_or_no_distinct_record": 15,
}
EXPECTED_24_IDS = [
    "SIP-1", "SIP-2", "SIP-3", "SIM-1", "SIM-2",
    "CFG-1", "CFG-2", "CFG-3", "TENV-1", "TENV-2", "TENV-3",
    "TRN-1", "TRN-2", "TRN-3", "RPT-1", "RPT-2", "RPT-3",
    "BSD-1", "BSD-2", "BSD-3", "BSD-4", "DEP-1", "REL-1", "REL-2",
]


def data_rows(rel_path):
    """Return the data rows of a CSV as a list of dicts (BOM-tolerant)."""
    with open(os.path.join(ROOT, rel_path), newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def check_split(rel_path, column, expected):
    rows = data_rows(rel_path)
    got = dict(collections.Counter(r[column].strip() for r in rows))
    ok = (got == expected and len(rows) == sum(expected.values()))
    label = "%s[%s]" % (rel_path, column)
    if ok:
        print("PASS  %s: %s (total %d)" % (label, got, len(rows)))
        return 0
    print("FAIL  %s: got %s expected %s" % (label, got, expected))
    return 1


def main():
    failures = 0
    try:
        failures += check_split(
            "block1_construction_audit/candidate_filtering_study.csv",
            "disposition", CANDIDATE_DISPOSITIONS)
        failures += check_split(
            "block1_construction_audit/generic_stride_baseline.csv",
            "baseline_status", BASELINE_STATUSES)

        snap = data_rows("block1_construction_audit/catalog_24records_audit_snapshot.csv")
        core = data_rows("00_stride_fpga_catalog/full_threat_taxonomy_supplement.csv")
        snap_ids = sorted(r[next(iter(snap[0]))].strip() for r in snap)
        core_ids = sorted(r[next(iter(core[0]))].strip() for r in core)
        if snap_ids == core_ids == sorted(EXPECTED_24_IDS):
            print("PASS  audit-snapshot IDs == core catalog == 24 expected IDs")
        else:
            failures += 1
            print("FAIL  ID match: snapshot=%d core=%d expected=24"
                  % (len(snap_ids), len(core_ids)))
    except FileNotFoundError as exc:
        failures += 1
        print("FAIL  file not found: %s" % exc)

    print()
    if failures:
        print("%d check(s) FAILED" % failures)
        return 1
    print("All Block 1 checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
