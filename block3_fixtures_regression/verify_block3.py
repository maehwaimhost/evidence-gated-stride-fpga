#!/usr/bin/env python3
"""Verify Block 3 (fixtures and schema-regression) frozen results for the
Evidence-Gated STRIDE for FPGA Development Toolchains evidence package.

Standard library only. Run from anywhere:

    python block3_fixtures_regression/verify_block3.py

Checks the 96-row case-record matrix split, the 8 schema-regression oracle
cases (detected == expected), and the 71 / 77 fixture file counts. Exits 0 if
every check passes, 1 otherwise.
"""
import collections
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SUPPORT_STATUS = {
    "full": 67,
    "integrity_gap": 12,
    "authority_gap": 5,
    "partial": 6,
    "unsupported": 6,
}
FILE_COUNTS = [
    ("block3_fixtures_regression/self_authored_case_test_files.csv", 71),
    ("block3_fixtures_regression/self_authored_injection_benchmark_files.csv", 77),
]


def data_rows(rel_path):
    """Return the data rows of a CSV as a list of dicts (BOM-tolerant)."""
    with open(os.path.join(ROOT, rel_path), newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def id_set(value):
    """Split a 'A; B' (or 'A, B') record-id cell into a comparable set."""
    return frozenset(p.strip() for p in value.replace(",", ";").split(";") if p.strip())


def main():
    failures = 0
    try:
        rows = data_rows("block3_fixtures_regression/self_authored_case_test_matrix.csv")
        got = dict(collections.Counter(r["support_status"].strip() for r in rows))
        if got == SUPPORT_STATUS and len(rows) == 96:
            print("PASS  case-test matrix: %s (total 96)" % got)
        else:
            failures += 1
            print("FAIL  case-test matrix: got %s (total %d) expected %s (total 96)"
                  % (got, len(rows), SUPPORT_STATUS))

        orc = data_rows("block3_fixtures_regression/self_authored_injection_benchmark_oracle.csv")
        bad = [o["injection_id"] for o in orc
               if o["oracle_status"].strip() != "expected_detected"
               or id_set(o["detected_threat_ids"]) != id_set(o["expected_threat_ids"])]
        if len(orc) == 8 and not bad:
            print("PASS  injection oracle: 8/8 expected_detected, detected == expected")
        else:
            failures += 1
            print("FAIL  injection oracle: rows=%d mismatches=%s" % (len(orc), bad))

        for rel, expected in FILE_COUNTS:
            n = len(data_rows(rel))
            if n == expected:
                print("PASS  %s: %d files" % (rel, n))
            else:
                failures += 1
                print("FAIL  %s: %d files (expected %d)" % (rel, n, expected))
    except FileNotFoundError as exc:
        failures += 1
        print("FAIL  file not found: %s" % exc)

    print()
    if failures:
        print("%d check(s) FAILED" % failures)
        return 1
    print("All Block 3 checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
